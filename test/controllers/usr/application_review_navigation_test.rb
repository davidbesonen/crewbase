require "test_helper"

class Usr::ApplicationReviewNavigationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("review-owner@example.com")
    @applicant = create_user("review-applicant@example.com")
    industry = Industry.create!(name: "Review Navigation")
    @company = Company.create!(name: "Review Company", contact_email: "review-company@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Review Role", description: "Review role", status: :published, workplace_type: :remote, employment_type: :contract)
    @application = @applicant.user_profile.job_applications.create!(job: @job)
  end

  test "entitled owner can return directly to the job's applicants" do
    plan = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4900, annual_price_cents: 49000, active: true, position: 2)
    @company.company_plans.create!(plan:)
    sign_in @owner, scope: :user

    get usr_job_application_path(@application)

    assert_response :success
    assert_select "a[href='#{usr_company_applications_path(@company, job_id: @job.id)}']", text: "Back to Applicants"
  end

  test "owner without pipeline access retains the company return link" do
    sign_in @owner, scope: :user

    get usr_job_application_path(@application)

    assert_select "a[href='#{usr_company_path(@company)}']", text: "Back to Company"
    assert_select "a", text: "Back to Applicants", count: 0
  end

  test "applicant returns to their own applications" do
    sign_in @applicant, scope: :user

    get usr_job_application_path(@application)

    assert_select "a[href='#{usr_job_applications_path}']", text: "Back to My Applications"
    assert_select "a", text: "Back to Applicants", count: 0
  end

  private

  def create_user(email)
    user = User.create!(first_name: "Review", last_name: "User", email:, password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
