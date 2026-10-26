class ConversationInbox
  def initialize(user:)
    @user = user
  end

  def results
    user.conversations
      .includes({ context: :job }, :latest_message, memberships: :user)
      .order(updated_at: :desc)
      .select { |conversation| conversation.accessible_to?(user) }
  end

  private

  attr_reader :user
end
