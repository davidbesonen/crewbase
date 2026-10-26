class RespondToNetworkConnection
  def initialize(connection:, recipient:, accept:)
    @connection, @recipient, @accept = connection, recipient, accept
  end

  def call
    raise ActiveRecord::RecordNotFound unless @connection.recipient == @recipient

    @connection.with_lock do
      raise ActiveRecord::RecordNotFound if @accept && UserBlock.between?(@connection.sender, @recipient)

      return @connection unless @connection.pending?

      @connection.update!(status: @accept ? :accepted : :declined, responded_at: Time.current)
      @connection.notifications.unread.update_all(read_at: Time.current)
      if @accept
        Notification.create!(recipient: @connection.sender, actor: @recipient, notifiable: @connection,
          kind: "network_accepted", message: "#{@recipient.full_name} accepted your connection request.")
      end
      @connection
    end
  end
end
