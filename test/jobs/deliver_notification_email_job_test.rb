require "test_helper"

class DeliverNotificationEmailJobTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Email", last_name: "Worker", email: "email-worker@example.com", password: "password123")
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @profile.occupations << Occupation.create!(name: "Camera Operator")
    company = Company.create!(name: "Email Crew", contact_email: "email-company@example.com", industries: [ Industry.create!(name: "Email film") ])
    @job = company.jobs.create!(title: "Camera Operator", description: "Camera work", employment_type: :contract,
      workplace_type: :on_site, status: :published, is_active: true, starts_at: 2.days.from_now)
  end

  test "delivery happens once and includes useful job and preference links" do
    delivery = make_delivery
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      2.times { DeliverNotificationEmailJob.perform_now(delivery.id) }
    end
    assert delivery.reload.sent?
    email = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email ], email.to
    assert_includes email.body.to_s, @job.title
    assert_includes email.body.to_s, "/usr/jobs/#{@job.id}"
    assert_includes email.body.to_s, "/usr/settings"
  end

  test "preferences are checked again at delivery time" do
    delivery = make_delivery
    @user.update!(job_alert_notifications_enabled: false)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert delivery.reload.skipped?
  end

  test "closed jobs and stale matching criteria are removed before delivery" do
    delivery = make_delivery
    @job.update!(status: :closed)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert delivery.reload.skipped?
  end

  test "a delivery interrupted after claiming is not replayed automatically" do
    delivery = make_delivery
    delivery.update!(status: :sending, attempted_at: 2.hours.ago)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert delivery.reload.sending?
  end

  test "transport failures remain observable and do not send again on retry" do
    delivery = make_delivery
    interceptor = Class.new do
      def self.delivering_email(_message)
        raise IOError, "Mail transport unavailable"
      end
    end
    ActionMailer::Base.register_interceptor(interceptor)
    assert_raises(IOError) { DeliverNotificationEmailJob.perform_now(delivery.id) }
    assert delivery.reload.failed?
    assert_equal "IOError", delivery.failure_class
    ActionMailer::Base.unregister_interceptor(interceptor)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
  ensure
    ActionMailer::Base.unregister_interceptor(interceptor)
  end

  private

  def make_delivery
    NotificationDelivery.create!(recipient: @user, kind: "job_alert", deduplication_key: "alert-#{@job.id}", payload: { job_ids: [ @job.id ] })
  end
end
