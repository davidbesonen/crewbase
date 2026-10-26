class ScheduleWorkerNotificationsJob < ApplicationJob
  queue_as :notifications

  def perform(kind)
    raise ArgumentError, "Unknown notification kind" unless kind.in?(%w[job_alert recommended_role upcoming_job_reminder])

    preference = NotificationDelivery::PREFERENCES.fetch(kind).to_s.delete_suffix("?")
    User.where(email_notifications_enabled: true, preference => true).find_each do |user|
      WorkerNotificationSchedule.new(user:, kind:).call
    end
  end
end
