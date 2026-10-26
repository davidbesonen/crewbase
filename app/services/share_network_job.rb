class ShareNetworkJob
  def initialize(job:, sender:, recipient:, note: nil)
    @job, @sender, @recipient, @note = job, sender, recipient, note
  end

  def call
    connection = NetworkConnection.accepted.between(@sender, @recipient).first!
    connection.with_lock do
      raise ActiveRecord::RecordNotFound if UserBlock.between?(@sender, @recipient)

      raise ActiveRecord::RecordNotFound unless connection.accepted?

      @job.with_lock do
        raise ActiveRecord::RecordNotFound unless @job.network_shareable?

        share = NetworkJobShare.find_by(job: @job, sender: @sender, recipient: @recipient)
        return share if share

        share = NetworkJobShare.create!(job: @job, sender: @sender, recipient: @recipient, note: @note)
        Notification.create!(recipient: @recipient, actor: @sender, notifiable: share,
          kind: "network_job_share", message: "#{@sender.full_name} shared a job with you.")
        share
      end
    end
  end
end
