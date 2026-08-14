require "test_helper"

class Usr::ConversationMessageComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  test "renders a stable personalized message bubble" do
    sender = User.create!(email: "bubble@example.com", first_name: "Live", last_name: "Sender", password: "password123")
    message = ContextualMessage.new(id: 42, sender:, body: "Hello <script>alert('no')</script>", created_at: Time.current)

    render_inline(Usr::ConversationMessageComponent.new(message:, current_user: sender))

    assert_css "#contextual_message_42.justify-content-end[data-message-id='42']"
    assert_text "Hello alert('no')"
    assert_no_css "script"
  end
end
