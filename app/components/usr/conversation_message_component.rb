class Usr::ConversationMessageComponent < ApplicationComponent
  def initialize(message:, current_user:)
    @message = message
    @current_user = current_user
  end

  private

  attr_reader :message, :current_user

  def sent_by_current_user?
    message.sender == current_user
  end
end
