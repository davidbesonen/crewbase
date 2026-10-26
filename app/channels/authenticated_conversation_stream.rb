# Turbo's default signed stream names are bearer tokens. Bind subscriptions to
# the logged-in participant as well, including requests to the default channel.
module AuthenticatedConversationStream
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])
    user = connection.current_user
    expected = conversation && user && self.class.signed_stream_name([ conversation, user ])
    if expected == params[:signed_stream_name] && conversation&.accessible_to?(user)
      super
    else
      reject
    end
  end
end
