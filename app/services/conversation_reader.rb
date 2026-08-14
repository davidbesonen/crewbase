class ConversationReader
  def initialize(membership:)
    @membership = membership
  end

  def call
    membership.transaction do
      membership.mark_as_read!
      membership.user.notifications
        .unread
        .where(notifiable: membership.conversation.messages)
        .find_each(&:mark_as_read!)
    end
  end

  private

  attr_reader :membership
end
