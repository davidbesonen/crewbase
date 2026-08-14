class ContextualMessageCreator
  class NotAuthorized < StandardError; end

  def initialize(context:, sender:, body:)
    @context = context
    @sender = sender
    @body = body
  end

  def call
    raise NotAuthorized unless participants.include?(sender)

    message = ContextualMessage.transaction do
      conversation = Conversation.find_or_create_by!(context:)
      participants.each { |user| conversation.memberships.find_or_create_by!(user:) }
      message = conversation.messages.create!(sender:, body:)
      conversation.memberships.find_by!(user: sender).mark_as_read!
      notify_recipients(message)
      message
    end

    ConversationMessageBroadcaster.new(message:).call
    message
  end

  private

  attr_reader :context, :sender, :body

  def participants
    @participants ||= ConversationParticipants.new(context:).users
  end

  def notify_recipients(message)
    participants.excluding(sender).each do |recipient|
      Notification.create!(
        recipient:,
        actor: sender,
        notifiable: message,
        kind: "contextual_message",
        message: "#{sender.full_name} sent a message about #{context.job.title}."
      )
    end
  end
end
