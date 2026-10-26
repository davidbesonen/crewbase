require "test_helper"

class RecommendationFeedbackTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Match", last_name: "Tester", email: "matches@example.com", password: "password123")
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current, capability_keys: [ "audio" ])
    @user.visits.create!
    company = Company.create!(name: "Feedback Productions", contact_email: "feedback@example.com", industries: [ Industry.create!(name: "Live") ])
    @job = company.jobs.create!(title: "Audio work", description: "Audio work", status: :published, is_active: true, employment_type: :contract, workplace_type: :on_site, required_capability_keys: [ "audio" ])
    sign_in @user
  end

  test "dismissed recommendations disappear and can be restored" do
    assert_equal [ @job ], WorkerJobRecommender.new(profile: @profile).results.map(&:job)
    post "/usr/jobs/#{@job.id}/recommendation_feedback", params: { reason: "not_relevant" }
    assert_response :redirect
    assert_empty WorkerJobRecommender.new(profile: @profile).results
    get "/usr/recommendation_feedback"
    assert_response :success
    assert_select "a", text: @job.title
    delete "/usr/jobs/#{@job.id}/recommendation_feedback"
    assert_equal [ @job ], WorkerJobRecommender.new(profile: @profile).results.map(&:job)
  end

  test "recommendation impressions deduplicate within a day" do
    2.times { get usr_dashboards_path }
    assert_equal 1, ProductEvent.where(user: @user, subject: @job, name: "recommendation_shown").count
  end

  test "recommendation visits are recorded only after a real recommendation was shown" do
    get usr_job_path(@job), params: { source: "recommendation" }
    assert_equal 0, ProductEvent.where(name: "recommendation_viewed").count
    get usr_dashboards_path
    2.times { get usr_job_path(@job), params: { source: "recommendation" } }
    assert_equal 1, ProductEvent.where(user: @user, name: "recommendation_viewed", job: @job).count
  end

  test "another member cannot restore my dismissed recommendations" do
    post "/usr/jobs/#{@job.id}/recommendation_feedback", params: { reason: "not_relevant" }
    other = User.create!(first_name: "Other", last_name: "Member", email: "other-match@example.com", password: "password123")
    sign_in other
    delete "/usr/jobs/#{@job.id}/recommendation_feedback"
    assert_empty WorkerJobRecommender.new(profile: @profile).results
  end
end
