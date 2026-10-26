require "test_helper"

class ProductMetricsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "events deduplicate per member and metrics distinguish activity from attribution" do
    member = User.create!(first_name: "Measure", last_name: "Me", email: "measure@example.com", password: "password123")
    2.times { ProductEvent.record(user: member, name: "onboarding_started", event_key: "once") }
    assert_equal 1, ProductEvent.count
    ProductEvent.record(user: member, name: "onboarding_completed", event_key: "once")
    metrics = Admin::ProductMetrics.new.results
    assert_equal 1, metrics[:events].fetch("onboarding_started")
    assert_equal 1, metrics[:events].fetch("onboarding_completed")
    assert_equal 0, metrics[:recommended_applications]
    assert_raises(ActiveRecord::RecordInvalid) { ProductEvent.record(user: member, name: "arbitrary_sensitive_payload") }
  end
end
