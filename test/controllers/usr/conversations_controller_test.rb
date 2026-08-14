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

    assert_response :no_content
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
