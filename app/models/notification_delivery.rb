class NotificationDelivery < ApplicationRecord
  PREFERENCES = {
    "job_alert" => :job_alert_notifications_enabled?,
    "recommended_role" => :recommended_role_notifications_enabled?,
    "upcoming_job_reminder" => :upcoming_job_reminder_notifications_enabled?
  }.freeze

  belongs_to :recipient, class_name: "User"
  enum :status, %w[pending sending sent skipped failed].index_with(&:itself)
  validates :kind, inclusion: { in: [ *PREFERENCES.keys, "job_offer" ] }
  validates :deduplication_key, presence: true

  def self.enqueue!(**attributes)
    delivery = create_or_find_by!(deduplication_key: attributes.fetch(:deduplication_key)) do |record|
      record.assign_attributes(attributes)
    end
    DeliverNotificationEmailJob.perform_later(delivery.id) if delivery.pending?
    delivery
  end

  def permitted?
    recipient.email_notifications_enabled? &&
      (!PREFERENCES.key?(kind) || recipient.public_send(PREFERENCES.fetch(kind)))
  end
end
