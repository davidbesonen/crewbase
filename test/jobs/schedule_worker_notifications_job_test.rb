require "test_helper"

class ScheduleWorkerNotificationsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Alert", last_name: "Worker", email: "alerts@example.com", password: "password123")
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @profile.occupations << Occupation.create!(name: "Camera Operator")
    company = Company.create!(name: "Alert Crew", contact_email: "alerts-company@example.com", industries: [ Industry.create!(name: "Alert film") ])
    @job = company.jobs.create!(title: "Camera Operator", description: "Camera work", employment_type: :contract,
      workplace_type: :on_site, status: :published, is_active: true, published_at: 1.hour.ago, starts_at: 2.days.from_now)
  end

  test "daily alerts match experience and deduplicate repeat scheduler runs" do
    assert_difference "NotificationDelivery.count", 1 do
      2.times { ScheduleWorkerNotificationsJob.perform_now("job_alert") }
    end
    delivery = NotificationDelivery.last
    assert_equal [ @job.id ], delivery.payload.fetch("job_ids")
    assert_equal "pending", delivery.status
    assert_enqueued_with(job: DeliverNotificationEmailJob, args: [ delivery.id ])
  end

  test "rolled back workflows never enqueue delivery before their records commit" do
    assert_no_enqueued_jobs only: DeliverNotificationEmailJob do
      NotificationDelivery.transaction do
        NotificationDelivery.enqueue!(recipient: @user, kind: "job_alert", deduplication_key: "rollback", payload: { job_ids: [ @job.id ] })
        raise ActiveRecord::Rollback
      end
    end
    assert_not NotificationDelivery.exists?(deduplication_key: "rollback")
  end

  test "category opt out and email opt out prevent scheduling" do
    @user.update!(job_alert_notifications_enabled: false)
    assert_no_difference "NotificationDelivery.count" do
      ScheduleWorkerNotificationsJob.perform_now("job_alert")
    end
    @user.update!(job_alert_notifications_enabled: true, email_notifications_enabled: false)
    assert_no_difference "NotificationDelivery.count" do
      ScheduleWorkerNotificationsJob.perform_now("job_alert")
    end
  end

  test "weekly recommendations include current matches and deduplicate within week" do
    @job.update!(published_at: 1.month.ago)
    assert_no_difference "NotificationDelivery.count" do
      ScheduleWorkerNotificationsJob.perform_now("job_alert")
    end
    assert_difference "NotificationDelivery.count", 1 do
      2.times { ScheduleWorkerNotificationsJob.perform_now("recommended_role") }
    end
    assert_equal [ @job.id ], NotificationDelivery.last.payload.fetch("job_ids")
  end
end
