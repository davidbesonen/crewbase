class ConversationMessageBroadcaster
  def initialize(message:)
    @message = message
  end

  def call
    participants = ConversationParticipants.new(context: message.conversation.context).users
    message.conversation.memberships.includes(:user).find_each do |membership|
      next unless participants.include?(membership.user)
      html = ApplicationController.render(
        Usr::ConversationMessageComponent.new(message:, current_user: membership.user),
        layout: false
      )
      Turbo::StreamsChannel.broadcast_append_to(
        message.conversation,
        membership.user,
        target: ActionView::RecordIdentifier.dom_id(message.conversation, :messages),
        html:
      )
    end
  end

  private

  attr_reader :message
end
