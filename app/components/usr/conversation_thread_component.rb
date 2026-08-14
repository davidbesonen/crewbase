class Usr::ConversationThreadComponent < ApplicationComponent
  renders_many :message_bubbles, Usr::ConversationMessageComponent

  def initialize(conversation:, messages:, current_user:)
    @conversation = conversation
    @messages = messages
    @current_user = current_user
  end

  private

  attr_reader :conversation, :messages, :current_user
end
