class ConversationMembership < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }

  def read?
    latest_message_at = conversation.messages.last&.created_at
    last_read_at.present? && latest_message_at.present? && last_read_at >= latest_message_at
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(last_read_at: Time.current)
  end
end
