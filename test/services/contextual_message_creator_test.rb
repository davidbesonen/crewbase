require "test_helper"

class ContextualMessageCreatorTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  self.fixture_table_names = []

  setup do
    @owner = create_user("message-owner@example.com", "Morgan", "Owner")
    @applicant = create_user("message-applicant@example.com", "Alex", "Applicant")
    industry = Industry.create!(name: "Messaging")
    company = Company.create!(name: "Message Co", contact_email: "messages@example.com", industries: [ industry ])
    CompanyAssignment.create!(company:, user: @owner, role: "owner")
    job = Job.create!(
      company:,
      title: "Lighting Designer",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      description: "Design the show"
    )
    @application = JobApplication.create!(job:, profile: @applicant.user_profile)
  end

  test "creates a contextual conversation, message, memberships, and recipient notification" do
    result = ContextualMessageCreator.new(
      context: @application,
      sender: @applicant,
      body: "Is travel covered?"
    ).call

    assert_equal @application, result.conversation.context
    assert_equal [ @applicant, @owner ].sort_by(&:id), result.conversation.users.sort_by(&:id)
    assert_equal "Is travel covered?", result.body
    assert result.conversation.memberships.find_by!(user: @applicant).read?
    assert_not result.conversation.memberships.find_by!(user: @owner).read?

    notification = @owner.notifications.find_by!(notifiable: result)
    assert_equal "contextual_message", notification.kind
    assert_includes notification.message, "Lighting Designer"
  end

  test "rejects a sender who is not a participant" do
    outsider = create_user("message-outsider@example.com", "Outside", "User")

    assert_raises ContextualMessageCreator::NotAuthorized do
      ContextualMessageCreator.new(context: @application, sender: outsider, body: "Hello").call
    end
  end

  test "reuses the conversation for later messages" do
    first = ContextualMessageCreator.new(context: @application, sender: @applicant, body: "First").call
    second = ContextualMessageCreator.new(context: @application, sender: @owner, body: "Second").call

    assert_equal first.conversation, second.conversation
    assert_equal 2, first.conversation.messages.count
  end

  test "broadcasts the persisted message to each participant's private stream" do
    conversation = Conversation.create!(context: @application)
    creator = ContextualMessageCreator.new(context: @application, sender: @applicant, body: "Live update")

    assert_broadcasts(stream_name(conversation, @applicant), 1) do
      assert_broadcasts(stream_name(conversation, @owner), 1) { creator.call }
    end
  end

  private

  def create_user(email, first_name, last_name)
    user = User.create!(
      email:,
      first_name:,
      last_name:,
      password: "password123",
      password_confirmation: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user
  end

  def stream_name(conversation, user)
    [ conversation, user ].map(&:to_gid_param).join(":")
  end
end
