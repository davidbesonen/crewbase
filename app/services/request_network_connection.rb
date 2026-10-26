class RequestNetworkConnection
  def initialize(sender:, recipient:, introduction: nil)
    @sender, @recipient, @introduction = sender, recipient, introduction
  end

  def call
    @sender.with_lock do
      raise ActiveRecord::RecordNotFound if UserBlock.between?(@sender, @recipient)

      existing = NetworkConnection.between(@sender, @recipient).first
      return existing if existing

      connection = NetworkConnection.create!(sender: @sender, recipient: @recipient, introduction: @introduction)
      Notification.create!(recipient: @recipient, actor: @sender, notifiable: connection,
        kind: "network_request", message: "#{@sender.full_name} would like to connect with you.")
      connection
    end
  rescue ActiveRecord::RecordNotUnique
    NetworkConnection.between(@sender, @recipient).first!
  end
end
