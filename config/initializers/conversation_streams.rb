Rails.application.config.to_prepare do
  Turbo::StreamsChannel.prepend(AuthenticatedConversationStream) unless Turbo::StreamsChannel < AuthenticatedConversationStream
end
