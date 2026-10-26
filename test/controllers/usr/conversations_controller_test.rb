require "test_helper"

class Usr::ConversationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("thread-owner@example.com")
    @applicant = create_user("thread-applicant@example.com")
    @outsider = create_user("thread-outsider@example.com")
    industry = Industry.create!(name: "Conversation Controller")
    company = Company.create!(name: "Thread Co", contact_email: "threads@example.com", industries: [ industry ])
    CompanyAssignment.create!(company:, user: @owner, role: "owner")
    job = Job.create!(
      company:,
      title: "Camera Operator",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      description: "Operate cameras"
    )
    @application = JobApplication.create!(job:, profile: @applicant.user_profile)
    @message = ContextualMessageCreator.new(
      context: @application,
      sender: @owner,
      body: "Can you work Friday?"
    ).call
    @conversation = @message.conversation
  end

  test "participant sees contextual inbox and thread, which marks membership read" do
    sign_in @applicant, scope: :user

    get usr_conversations_path
    assert_response :success
    assert_select "a[href='#{usr_conversation_path(@conversation)}']", text: /Camera Operator/
    assert_select ".badge", text: "Unread"

    get usr_conversation_path(@conversation)
    assert_response :success
    assert_select "h1", text: /Camera Operator/
    assert_select "[data-message-id='#{@message.id}']", text: /Can you work Friday?/
    assert @conversation.memberships.find_by!(user: @applicant).reload.read?
    assert @applicant.notifications.find_by!(notifiable: @message).reload.read?
  end

  test "participant sends a message from the thread" do
    sign_in @applicant, scope: :user

    assert_difference -> { @conversation.messages.count }, 1 do
      post usr_conversation_contextual_messages_path(@conversation), params: {
        contextual_message: { body: "Yes, I can." }
      }
    end

    assert_redirected_to usr_conversation_path(@conversation)
    assert_equal "Yes, I can.", @conversation.messages.order(:id).last.body
  end

  test "participant sends a message without a page reload from a Turbo form" do
    sign_in @applicant, scope: :user

    assert_difference -> { @conversation.messages.count }, 1 do
      post usr_conversation_contextual_messages_path(@conversation),
        params: { contextual_message: { body: "Received live." } },
        as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action='append']"
  end

  test "outsider cannot view or post to a conversation" do
    sign_in @outsider, scope: :user

    get usr_conversation_path(@conversation)
    assert_response :not_found

    sign_in @outsider, scope: :user
    assert_no_difference -> { @conversation.messages.count } do
      post usr_conversation_contextual_messages_path(@conversation), params: {
        contextual_message: { body: "I should not be here." }
      }
    end
    assert_response :not_found
  end

  test "completed conversations remain readable but reject messages" do
    @application.job.update!(status: :completed)
    sign_in @applicant, scope: :user
    get usr_conversation_path(@conversation)
    assert_response :success
    assert_select "textarea", count: 0
    assert_select "[data-conversation-archived]"
    assert_no_difference("ContextualMessage.count") do
      post usr_conversation_contextual_messages_path(@conversation), params: { contextual_message: { body: "Too late" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "attachment only messages are supported" do
    sign_in @applicant, scope: :user
    file = Rack::Test::UploadedFile.new(StringIO.new("Call sheet"), "text/plain", false, original_filename: "call-sheet.txt")
    post usr_conversation_contextual_messages_path(@conversation), params: { contextual_message: { body: "", files: [ file ] } }
    assert_response :redirect
    assert_equal "call-sheet.txt", @conversation.messages.last.files.sole.filename.to_s
  end

  test "former owners lose access even with a conversation membership" do
    @application.job.company.company_assignments.where(user: @owner).destroy_all
    sign_in @owner, scope: :user
    get usr_conversation_path(@conversation)
    assert_response :not_found
  end

  test "message files require live participant authorization and have no public storage route" do
    @message.files.attach(io: StringIO.new("Private call sheet"), filename: "private.txt", content_type: "text/plain")
    blob = @message.files.sole.blob
    sign_in @applicant, scope: :user
    get "/files/#{blob.signed_id}/private.txt"
    assert_response :success
    assert_equal "Private call sheet", response.body
    assert_includes response.headers["Cache-Control"], "no-store"
    sign_in @outsider, scope: :user
    get "/files/#{blob.signed_id}/private.txt"
    assert_response :not_found
    get "/rails/active_storage/blobs/redirect/#{blob.signed_id}/private.txt"
    assert_response :not_found
  end

  test "signed file IDs cannot be attached to a different conversation" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("secret"), filename: "secret.txt", content_type: "text/plain")
    sign_in @applicant, scope: :user
    assert_no_difference("ContextualMessage.count") do
      post usr_conversation_contextual_messages_path(@conversation), params: { contextual_message: { body: "stolen", files: [ blob.signed_id ] } }
    end
    assert_response :unprocessable_entity
  end

  test "past end dates archive conversations without needing a scheduled job" do
    @application.job.update!(ends_at: 1.minute.ago)
    sign_in @applicant, scope: :user
    get usr_conversation_path(@conversation)
    assert_response :success
    assert_select "[data-conversation-archived]"
    assert_no_difference("ContextualMessage.count") do
      post usr_job_application_contextual_messages_path(@application), params: { contextual_message: { body: "late" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  private

  def create_user(email)
    user = User.create!(
      email:,
      first_name: "Thread",
      last_name: email.split("@").first,
      password: "password123",
      password_confirmation: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
