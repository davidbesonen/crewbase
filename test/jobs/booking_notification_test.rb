require "test_helper"

class BookingNotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  self.fixture_table_names = []

  setup do
    @worker = User.create!(first_name: "Booked", last_name: "Worker", email: "booked-notification@example.com", password: "password123")
    @profile = @worker.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner = User.create!(first_name: "Booking", last_name: "Owner", email: "booking-notification@example.com", password: "password123")
    company = Company.create!(name: "Booking Notifications", contact_email: "bookings@example.com", industries: [ Industry.create!(name: "Booking notifications") ])
    @job = company.jobs.create!(title: "Camera", description: "Camera work", employment_type: :contract,
      workplace_type: :on_site, status: :published, starts_at: 12.hours.from_now, ends_at: 16.hours.from_now)
    @application = @job.job_applications.create!(profile: @profile, status: :accepted)
  end

  test "only accepted offers and legacy bookings receive a reminder once" do
    assert_difference "NotificationDelivery.count", 1 do
      2.times { ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder") }
    end
    assert_equal @application.id, NotificationDelivery.last.payload["application_id"]
    @application.update!(status: :shortlisted)
    @offer = offer(status: :pending)
    assert_no_difference "NotificationDelivery.count" do
      ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder")
    end
    @offer.update!(status: :accepted)
    @application.update!(status: :accepted)
    assert_difference "NotificationDelivery.count", 1 do
      2.times { ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder") }
    end
    assert_equal @offer.id, NotificationDelivery.last.payload["offer_id"]
  end

  test "cancelled accepted offer suppresses reminder and cannot fall back to legacy application" do
    booked = offer(status: :accepted)
    ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder")
    delivery = NotificationDelivery.last
    booked.update!(status: :cancelled)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert delivery.reload.skipped?
    assert_no_difference "NotificationDelivery.count" do
      ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder")
    end
  end

  test "reminders use agreed offer dates and skip completed jobs" do
    booked = offer(status: :accepted)
    @job.update!(starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    assert_difference "NotificationDelivery.count", 1 do
      ScheduleWorkerNotificationsJob.perform_now("upcoming_job_reminder")
    end
    delivery = NotificationDelivery.last
    assert_equal booked.id, delivery.payload["offer_id"]
    @job.update!(status: :completed)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert delivery.reload.skipped?
  end

  test "new offer email links to agreed terms and respects global preference" do
    pending = offer(status: :pending)
    delivery = NotificationDelivery.create!(recipient: @worker, kind: "job_offer", deduplication_key: "offer-mail", payload: { offer_id: pending.id })
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      DeliverNotificationEmailJob.perform_now(delivery.id)
    end
    assert_includes ActionMailer::Base.deliveries.last.body.to_s, "/usr/job_offers/#{pending.id}"
    delivery2 = NotificationDelivery.create!(recipient: @worker, kind: "job_offer", deduplication_key: "offer-optout", payload: { offer_id: pending.id })
    @worker.update!(email_notifications_enabled: false)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      DeliverNotificationEmailJob.perform_now(delivery2.id)
    end
    assert delivery2.reload.skipped?
  end

  private

  def offer(status:)
    JobOffer.create!(job_application: @application, profile: @profile, sender: @owner, role: "Camera operator",
      starts_at: @job.starts_at, ends_at: @job.ends_at, rate: 450, currency: "USD", pay_unit: "daily", status:)
  end
end
