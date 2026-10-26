require "test_helper"

class ConversationStreamTest < ActionCable::Channel::TestCase
  tests Turbo::StreamsChannel
  self.fixture_table_names = []

  setup do
    @owner = User.create!(email: "stream-owner@example.com", first_name: "Stream", last_name: "Owner", password: "password123")
    @worker = User.create!(email: "stream-worker@example.com", first_name: "Stream", last_name: "Worker", password: "password123")
    profile = @worker.profiles.create!(profile_type: "user")
    industry = Industry.create!(name: "Streams")
    @company = Company.create!(name: "Streams", contact_email: "streams@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    job = @company.jobs.create!(title: "Crew", description: "Crew", workplace_type: :remote, employment_type: :contract)
    application = job.job_applications.create!(profile:)
    @conversation = Conversation.create!(context: application)
    @signed_name = Turbo::StreamsChannel.signed_stream_name([ @conversation, @owner ])
  end

  test "a participant can subscribe to their own stream" do
    stub_connection current_user: @owner
    subscribe conversation_id: @conversation.id, signed_stream_name: @signed_name
    assert subscription.confirmed?
    assert_has_stream [ @conversation, @owner ].map(&:to_gid_param).join(":")
  end

  test "even another participant cannot subscribe to a copied personal stream" do
    stub_connection current_user: @worker
    subscribe conversation_id: @conversation.id, signed_stream_name: @signed_name
    assert subscription.rejected?
  end

  test "former owners cannot subscribe with an old token" do
    @company.company_assignments.destroy_all
    stub_connection current_user: @owner
    subscribe conversation_id: @conversation.id, signed_stream_name: @signed_name
    assert subscription.rejected?
  end
end
