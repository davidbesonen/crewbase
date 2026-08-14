class ConversationInbox
  def initialize(user:)
    @user = user
  end

  def results
    user.conversations
      .includes({ context: :job }, :messages, memberships: :user)
      .order(updated_at: :desc)
  end

  private

  attr_reader :user
end
