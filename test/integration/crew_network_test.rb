require "test_helper"

class CrewNetworkTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user, @peer, @outsider = %w[member peer outsider].map do |name|
      user = User.create!(first_name: name.capitalize, last_name: "Crew", email: "network-#{name}@example.com", password: "password123")
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.assignments.create!(role: Role.find_or_create_by!(name: "user"))
      user.visits.create!
      user
    end
    sign_in @user, scope: :user
  end

  test "a member can request a connection and only its recipient can accept it" do
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id, introduction: "Great working with you." } }
    assert_response :redirect
    connection = NetworkConnection.last
    assert connection.pending?
    assert_equal @user, connection.sender
    assert_equal @peer, connection.recipient
    assert_equal 1, @peer.notifications.where(kind: "network_request").count

    patch "/usr/network_connections/#{connection.id}/accept"
    assert_response :not_found
    sign_in @outsider, scope: :user
    patch "/usr/network_connections/#{connection.id}/accept"
    assert_response :not_found
    sign_in @peer, scope: :user
    patch "/usr/network_connections/#{connection.id}/accept"
    assert_response :redirect
    assert connection.reload.accepted?
    get "/usr/network"
    assert_response :success
    assert_select "a[href='/usr/profiles/#{@user.user_profile.id}']", text: "Member Crew"
    get "/usr/notifications"
    assert_response :success
  end

  test "requests are private and cannot target self or forge the sender" do
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id, sender_id: @outsider.id } }
    connection = NetworkConnection.last
    assert_equal @user.id, connection.sender_id
    sign_in @outsider, scope: :user
    get "/usr/network?tab=requests&user_id=#{@peer.id}"
    assert_response :success
    assert_select "[data-network-connection='#{connection.id}']", count: 0
    sign_in @user, scope: :user
    assert_no_difference "NetworkConnection.count" do
      post "/usr/network_connections", params: { network_connection: { profile_id: @user.user_profile.id } }
    end
    assert_response :unprocessable_entity
  end

  test "duplicate and reverse requests do not duplicate notifications or imply acceptance" do
    2.times do
      post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id } }
    end
    sign_in @peer, scope: :user
    post "/usr/network_connections", params: { network_connection: { profile_id: @user.user_profile.id } }
    assert_equal 1, NetworkConnection.count
    assert NetworkConnection.first.pending?
    assert_equal 1, Notification.where(kind: "network_request").count
  end

  test "recipient can decline and sender can cancel but a stranger cannot remove a connection" do
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id } }
    connection = NetworkConnection.last
    sign_in @outsider, scope: :user
    delete "/usr/network_connections/#{connection.id}"
    assert_response :not_found
    sign_in @peer, scope: :user
    patch "/usr/network_connections/#{connection.id}/decline"
    assert_response :redirect
    assert connection.reload.declined?
    sign_in @user, scope: :user
    delete "/usr/network_connections/#{connection.id}"
    assert_response :not_found
  end

  test "only accepted connections receive job shares and only participants can view them" do
    company = Company.create!(name: "Network Production", contact_email: "network-production@example.com", industries: [ Industry.create!(name: "Network Events") ])
    job = company.jobs.create!(title: "Stage crew", employment_type: :contract, workplace_type: :on_site, description: "Stage call", status: :published)
    connection = NetworkConnection.create!(sender: @user, recipient: @peer, status: :accepted)
    post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id, note: "Thought of you for this." } }
    assert_response :redirect
    share = NetworkJobShare.last
    assert_equal @user, share.sender
    assert_equal "Thought of you for this.", share.note
    assert_equal 1, @peer.notifications.where(kind: "network_job_share").count
    assert_equal 0, job.job_applications.count
    assert_no_difference "NetworkJobShare.count" do
      post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @outsider.id } }
    end
    assert_response :not_found
    sign_in @outsider, scope: :user
    get "/usr/network_job_shares/#{share.id}"
    assert_response :not_found
    sign_in @peer, scope: :user
    get "/usr/network_job_shares/#{share.id}"
    assert_response :success
    assert_select "a[href='/usr/jobs/#{job.id}']", text: "View job"
    get "/usr/notifications"
    assert_response :success
    assert_select "a[href='/usr/network_job_shares/#{share.id}']"
    job.update!(status: :draft)
    get "/usr/network_job_shares/#{share.id}"
    assert_response :success
    assert_select "a[href='/usr/jobs/#{job.id}']", count: 0
    sign_in @user, scope: :user
    post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id } }
    assert_response :not_found
    job.update!(status: :published)
    delete "/usr/network_connections/#{connection.id}"
    post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id } }
    assert_response :not_found
  end

  test "network navigation and profile connection form are discoverable" do
    get "/usr/network"
    assert_response :success
    assert_select ".workspace-sidenav a.active[href='/usr/network']", count: 2
    get "/usr/profiles/#{@peer.user_profile.id}"
    assert_response :success
    assert_select "a[href='/usr/network_connections/new?profile_id=#{@peer.user_profile.id}']", text: "Connect"
    get "/usr/network_connections/new", params: { profile_id: @peer.user_profile.id }
    assert_response :success
    assert_select "label[for='network_connection_introduction']", count: 1
  end

  test "pending connections cannot share jobs and repeated shares are idempotent" do
    company = Company.create!(name: "Sharing Production", contact_email: "sharing@example.com", industries: [ Industry.create!(name: "Sharing Events") ])
    job = company.jobs.create!(title: "Audio call", employment_type: :contract, workplace_type: :on_site, description: "Audio", status: :published)
    connection = NetworkConnection.create!(sender: @user, recipient: @peer)
    post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id } }
    assert_response :not_found
    connection.update!(status: :accepted)
    sign_in @user, scope: :user
    2.times do
      post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id, note: "Check this out" } }
      assert_match %r{/usr/network_job_shares/\d+\z}, response.location
    end
    assert_equal 1, NetworkJobShare.count
    assert_equal 1, Notification.where(kind: "network_job_share").count
    get "/usr/jobs/#{job.id}/network_job_shares/new"
    assert_response :success
    assert_select "label[for='network_job_share_note']", count: 1
    job.update!(application_deadline: 1.day.ago)
    post "/usr/jobs/#{job.id}/network_job_shares", params: { network_job_share: { recipient_id: @peer.id } }
    assert_response :not_found
  end

  test "network search is private and matches a connection's role" do
    @peer.user_profile.occupations << Occupation.create!(name: "Lighting Programmer")
    NetworkConnection.create!(sender: @peer, recipient: @user, status: :accepted)
    NetworkConnection.create!(sender: @peer, recipient: @outsider, status: :accepted)
    get "/usr/network", params: { q: "Lighting" }
    assert_response :success
    assert_select ".network-person", count: 1
    assert_select ".network-person", text: /Peer Crew/
    get "/usr/network", params: { q: "Outsider" }
    assert_select ".network-person", count: 0
  end

  test "requests validate length without sending a notification and can be canceled" do
    assert_no_difference "Notification.count" do
      post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id, introduction: "x" * 501 } }
    end
    assert_response :unprocessable_entity
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id } }
    connection = NetworkConnection.last
    delete "/usr/network_connections/#{connection.id}"
    assert_response :redirect
    assert_not NetworkConnection.exists?(connection.id)
    assert_empty @peer.notifications.where(kind: "network_request")
  end
end
