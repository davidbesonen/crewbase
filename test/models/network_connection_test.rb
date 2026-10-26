require "test_helper"

class NetworkConnectionTest < ActiveSupport::TestCase
  test "cannot connect to self even with an existing connection to someone else" do
    NetworkConnection.create!(sender: users(:one), recipient: users(:two))
    assert_raises ActiveRecord::RecordInvalid do
      RequestNetworkConnection.new(sender: users(:one), recipient: users(:one)).call
    end
  end

  test "database prevents reverse duplicates and self connections" do
    NetworkConnection.create!(sender: users(:one), recipient: users(:two))
    assert_raises ActiveRecord::RecordNotUnique do
      NetworkConnection.transaction(requires_new: true) do
        NetworkConnection.new(sender: users(:two), recipient: users(:one)).save!(validate: false)
      end
    end
    assert_raises ActiveRecord::StatementInvalid do
      NetworkConnection.transaction(requires_new: true) do
        NetworkConnection.new(sender: users(:one), recipient: users(:one)).save!(validate: false)
      end
    end
  end

  test "a declined request cannot be reversed by replaying acceptance" do
    connection = NetworkConnection.create!(sender: users(:one), recipient: users(:two))
    RespondToNetworkConnection.new(connection:, recipient: users(:two), accept: false).call
    RespondToNetworkConnection.new(connection:, recipient: users(:two), accept: true).call
    assert connection.reload.declined?
    assert_empty NetworkConnection.connected_users(users(:one))
  end

  test "connection and share notes are bounded" do
    assert_not NetworkConnection.new(sender: users(:one), recipient: users(:two), introduction: "x" * 501).valid?
    connection = NetworkConnection.create!(sender: users(:one), recipient: users(:two), status: :accepted)
    share = NetworkJobShare.new(sender: connection.sender, recipient: connection.recipient, job: jobs(:one), note: "x" * 1001)
    assert_not share.valid?
    assert share.errors[:note].any?
    assert share.errors[:job].any?
  end
end
