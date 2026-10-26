class ContextualMessageCreator
  class NotAuthorized < StandardError; end
  class Archived < StandardError; end

  def initialize(context:, sender:, body:, files: [])
    @context = context
    @sender = sender
    @body = body.to_s
    @files = files
  end

  def call
    raise NotAuthorized unless participants.include?(sender)
    raise Archived, "This conversation is archived. Its messages and files are still available." if context.job.conversation_archived?

    message = ContextualMessage.transaction do
      conversation = Conversation.find_or_create_by!(context:)
      participants.each { |user| conversation.memberships.find_or_create_by!(user:) }
      message = conversation.messages.create!(sender:, body:, files:)
      conversation.memberships.find_by!(user: sender).mark_as_read!
      notify_recipients(message)
      message
    end

    ConversationMessageBroadcaster.new(message:).call
    message
  end

  private

  attr_reader :context, :sender, :body, :files

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
