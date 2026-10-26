class Usr::ConversationInboxComponent < ApplicationComponent
  def initialize(conversations:, current_user:)
    @conversations = conversations
    @current_user = current_user
  end

  private

  attr_reader :conversations, :current_user

  def unread?(conversation)
    conversation.memberships.detect { |item| item.user_id == current_user.id }&.unread?
  end

  def participants(conversation)
    conversation.memberships.map(&:user).reject { |user| user == current_user }.map(&:full_name).to_sentence
  end
end
