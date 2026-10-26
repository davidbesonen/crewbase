require "test_helper"

class ProductPrivacyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @member, @other, @admin = %w[member other admin].map do |name|
      user = User.create!(first_name: name, last_name: "Privacy", email: "privacy-#{name}@example.com", password: "password123")
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.assignments.create!(role: Role.find_or_create_by!(name: name == "admin" ? "admin" : "user"))
      user
    end
    company = Company.create!(name: "Privacy Work", contact_email: "privacy-work@example.com", industries: [ Industry.create!(name: "Privacy Industry") ])
    @job = company.jobs.create!(title: "Privacy Job", description: "Crew", employment_type: :contract, workplace_type: :on_site, status: :published)
    sign_in @member
  end

  test "product metrics are admin only and render aggregate counts without member identifiers" do
    ProductEvent.record(user: @other, name: "onboarding_started", event_key: "once")
    get "/admin/product_metrics"
    assert_redirected_to usr_dashboards_path
    sign_in @admin
    get "/admin/product_metrics"
    assert_response :success
    assert_select "h1", text: "Product outcomes"
    assert_no_match @other.email, response.body
    assert_no_match @other.full_name, response.body
  end

  test "feedback ignores forged ownership and rejects inaccessible job ids" do
    post "/usr/jobs/#{@job.id}/recommendation_feedback", params: { reason: "timing", user_id: @other.id }
    assert_response :redirect
    assert_equal @member.id, RecommendationFeedback.last.user_id
    sign_in @other
    get "/usr/recommendation_feedback"
    assert_response :success
    assert_select "h2", text: @job.title, count: 0
    @job.update!(status: :draft)
    assert_no_difference "RecommendationFeedback.count" do
      post "/usr/jobs/#{@job.id}/recommendation_feedback", params: { reason: "pay" }
    end
    assert_response :not_found
  end

  test "quick start ignores forged account and publication attributes" do
    @member.user_profile.update!(completed_at: nil)
    patch "/usr/onboarding", params: { onboarding: { intent: "find_work", user_id: @other.id, completed_at: Time.current, onboarding_completed_at: Time.current } }
    assert_response :redirect
    assert_equal "find_work", @member.reload.onboarding_intent
    assert_nil @other.reload.onboarding_intent
    assert_nil @member.user_profile.reload.completed_at
  end

  test "recommendation attribution cannot cross between members or jobs" do
    ProductEvent.record(user: @other, name: "recommendation_shown", subject: @job, event_key: "shown")
    ProductEvent.record(user: @member, name: "application_submitted", subject: @job, event_key: "application")
    assert_equal 0, Admin::ProductMetrics.new.results[:recommended_applications]
    ProductEvent.record(user: @member, name: "recommendation_shown", subject: @job, event_key: "shown")
    # An impression after submission cannot retroactively cause an application.
    assert_equal 0, Admin::ProductMetrics.new.results[:recommended_applications]
    ProductEvent.where(user: @member, name: "recommendation_shown").update_all(created_at: 1.minute.ago)
    assert_equal 1, Admin::ProductMetrics.new.results[:recommended_applications]
  end
end
