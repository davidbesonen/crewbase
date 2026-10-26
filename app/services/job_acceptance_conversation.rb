class JobAcceptanceConversation
  def initialize(application:, reviewer:)
    @application = application
    @reviewer = reviewer
  end

  def call
    conversation = Conversation.find_or_create_by!(context: @application)
    ConversationParticipants.new(context: @application).users.each do |user|
      conversation.memberships.find_or_create_by!(user:)
    end
    unless conversation.messages.exists?(event_key: "accepted")
      message = conversation.messages.create!(sender: @reviewer, event_key: "accepted",
        body: "#{@application.profile.user.full_name} has been accepted for #{@application.job.title}. Use this conversation to coordinate the job.")
      Notification.create!(recipient: @application.profile.user, actor: @reviewer, notifiable: message,
        kind: "contextual_message", message: "You have been accepted for #{@application.job.title}.")
      ActiveRecord.after_all_transactions_commit { ConversationMessageBroadcaster.new(message:).call }
    end
    conversation
  end
end
