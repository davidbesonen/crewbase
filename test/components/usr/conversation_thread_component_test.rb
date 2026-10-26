require "test_helper"

class Usr::ConversationThreadComponentTest < ViewComponent::TestCase
  test "an ended job keeps history and removes the composer" do
    user = User.new(id: 1, first_name: "Crew", last_name: "Member")
    job = Job.new(title: "Tour", ends_at: 1.minute.ago)
    conversation = Conversation.new(id: 99, context: JobApplication.new(job:))
    message = ContextualMessage.new(id: 7, sender: user, body: "See you there", created_at: 1.day.ago)
    render_inline(Usr::ConversationThreadComponent.new(conversation:, messages: [ message ], current_user: user)) do |thread|
      thread.with_message_bubble(message:, current_user: user)
    end
    assert_text "See you there"
    assert_text "Archived conversation"
    assert_no_selector "form"
  end

  test "active conversations provide files and acceptance notices without attributing them to a person" do
    user = User.new(id: 1, first_name: "Crew", last_name: "Member")
    job = Job.new(title: "Tour", ends_at: 1.day.from_now)
    conversation = Conversation.new(id: 99, context: JobApplication.new(job:))
    message = ContextualMessage.new(id: 7, sender: user, body: "Crew Member has been accepted for Tour.", event_key: "accepted", created_at: Time.current)
    render_inline(Usr::ConversationThreadComponent.new(conversation:, messages: [ message ], current_user: user)) do |thread|
      thread.with_message_bubble(message:, current_user: user)
    end
    assert_selector ".conversation-event", text: "Crew Member has been accepted"
    assert_no_selector ".message-author"
    assert_selector "input[type='file'][multiple]"
    assert_selector "#message-errors[aria-live='assertive']"
    assert_text "35 MB"
  end
end
