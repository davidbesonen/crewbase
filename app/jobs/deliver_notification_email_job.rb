class DeliverNotificationEmailJob < ApplicationJob
  queue_as :notifications
  self.enqueue_after_transaction_commit = true

  def perform(delivery_id)
    delivery = NotificationDelivery.find_by(id: delivery_id)
    return unless delivery

    content = nil
    claimed = delivery.with_lock do
      next false unless delivery.pending?

      content = NotificationEmailContent.new(delivery:)
      unless delivery.permitted? && content.available?
        delivery.update!(status: :skipped)
        next false
      end
      delivery.update!(status: :sending, attempted_at: Time.current)
      true
    end
    return unless claimed

    # Commit the claim before SMTP. An interrupted or ambiguous send needs operator
    # review; automatic retries could send the same email twice.
    WorkerNotificationMailer.with(delivery:, content:).update.deliver_now
    delivery.update!(status: :sent, sent_at: Time.current)
  rescue StandardError => error
    delivery&.update!(status: :failed, failure_class: error.class.name) if claimed
    Rails.error.report(error, handled: false)
    raise
  end
end
