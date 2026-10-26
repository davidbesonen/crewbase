require "test_helper"

class Admin::OperationalReadinessTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "configuration checks never treat example mail settings or missing providers as ready" do
    snapshot = Admin::OperationalReadiness.new(environment: {}).call
    refute snapshot.fetch(:checks).find { |check| check.name == "Email configuration" }.ready?
    refute snapshot.fetch(:checks).find { |check| check.name == "Billing configuration" }.ready?
    assert snapshot.fetch(:checks).any? { |check| check.name == "Backup restoration" && !check.ready? }
  end

  test "configured email and billing are only configuration checks not production verification" do
    environment = { "MAILER_FROM" => "crew@example.org", "APP_HOST" => "app.example.org", "SMTP_ADDRESS" => "smtp.example.org",
      "SMTP_USERNAME" => "user", "SMTP_PASSWORD" => "secret", "STRIPE_SECRET_KEY" => "configured", "STRIPE_WEBHOOK_SECRET" => "configured" }
    snapshot = Admin::OperationalReadiness.new(environment:).call
    assert snapshot.fetch(:checks).find { |check| check.name == "Email configuration" }.ready?
    assert snapshot.fetch(:checks).find { |check| check.name == "Billing configuration" }.ready?
    assert_includes snapshot.fetch(:checks).map(&:detail).join(" "), "not verified"
  end

  test "delivery and unprocessed billing failures are visible without message bodies or secrets" do
    user = User.create!(first_name: "Ops", last_name: "Crew", email: "ops@example.com", password: "password123")
    NotificationDelivery.create!(recipient: user, kind: "job_alert", deduplication_key: "ops-failed", status: :failed, failure_class: "Net::SMTPFatalError")
    NotificationDelivery.create!(recipient: user, kind: "job_alert", deduplication_key: "ops-stuck", status: :sending, attempted_at: 1.hour.ago)
    StripeEvent.create!(stripe_event_id: "evt_unprocessed", event_type: "invoice.paid", payload: {})
    snapshot = Admin::OperationalReadiness.new(environment: {}).call
    assert_equal 1, snapshot.fetch(:delivery_counts).fetch("failed")
    assert_equal 1, snapshot.fetch(:uncertain_deliveries)
    assert_equal 1, snapshot.fetch(:unprocessed_stripe_events)
  end
end
