require "test_helper"

class Admin::DashboardQueryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "returns zero-filled daily sign-in and growth series" do
    users_before = User.count
    sign_ins_before = Visit.where(created_at: 3.days.ago.beginning_of_day..Time.current.end_of_day).count
    user = User.create!(email: "metric@example.com", first_name: "Metric", last_name: "User", password: "password123", created_at: 2.days.ago)
    user.visits.create!(created_at: 1.day.ago)
    range = 3.days.ago.to_date..Time.current.to_date

    result = Admin::DashboardQuery.new(date_range: range).call

    assert_equal range.to_a.map(&:iso8601), result.fetch(:labels)
    assert_equal range.count, result.fetch(:sign_ins).length
    assert_equal sign_ins_before + 1, result.fetch(:sign_ins).sum
    assert_equal users_before + 1, result.dig(:totals, :users)
  end
end
