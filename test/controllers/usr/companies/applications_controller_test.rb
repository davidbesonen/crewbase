require "test_helper"

class Usr::Companies::ApplicationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("pipeline-controller-owner@example.com")
    @outsider = create_user("pipeline-controller-outsider@example.com")
    applicant = create_user("pipeline-controller-applicant@example.com", first_name: "Taylor")
    industry = Industry.create!(name: "Pipeline Controller")
    @company = Company.create!(
      name: "Controller Pipeline Co",
      contact_email: "controller-pipeline@example.com",
      industries: [ industry ],
      is_public: true
    )
    CompanyAssignment.create!(company: @company, user: @owner, role: "owner")
    team = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan: team)
    @job = Job.create!(
      company: @company,
      title: "Stage Manager",
      workplace_type: :on_site,
      employment_type: :full_time,
      status: :published,
      description: "Stage role"
    )
    @application = JobApplication.create!(
      job: @job,
      profile: applicant.user_profile,
      status: :shortlisted
    )
    @application.profile.occupations << Occupation.create!(name: "Stage Manager")
  end

  test "owner can view and filter the application pipeline" do
    sign_in @owner, scope: :user

    get usr_company_applications_path(@company), params: { status: "shortlisted" }

    assert_response :success
    assert_select "h1", text: "Application Pipeline"
    assert_select "[data-pipeline-application='#{@application.id}']"
    assert_select "[data-pipeline-application='#{@application.id}'] h2[data-recommended-applicant]" do
      assert_select "a", text: @application.profile.user.full_name
      assert_select ".badge.text-bg-success.recommended-applicant-badge", text: "Recommended Applicant"
      assert_select ".bi-stars", count: 1
    end
    assert_select "[data-pipeline-application='#{@application.id}'] [data-recommendation-reason]", text: /Matches Stage Manager/ do
      assert_select ".bi-stars", count: 1
    end
    assert_select "option[selected]", text: "Shortlisted"
  end

  test "project filter is preserved by pipeline stage and form links" do
    project = @company.projects.create!(name: "Pipeline Project")
    @job.update!(project:)
    sign_in @owner, scope: :user

    get usr_company_applications_path(@company), params: { project_id: project.id }

    assert_response :success
    assert_select "a[data-pipeline-stage][href*='project_id=#{project.id}']", count: JobApplication.review_pipeline_statuses.size
    assert_select "form input[type='hidden'][name='project_id'][value='#{project.id}']"
    assert_select "p", text: /1 total application/
  end

  test "pipeline links back to gig staffing when opened from its review applications link" do
    @job.update!(posting_type: :multi_position)
    sign_in @owner, scope: :user

    get usr_company_applications_path(@company), params: {
      job_id: @job.id,
      return_to: "staffing"
    }

    assert_response :success
    assert_select "a[href='#{usr_job_crew_path(@job)}']", text: "Back to Staff This Gig"
  end

  test "pipeline does not show a staffing back link without the staffing return context" do
    @job.update!(posting_type: :multi_position)
    sign_in @owner, scope: :user

    get usr_company_applications_path(@company), params: { job_id: @job.id }

    assert_response :success
    assert_select "a", text: "Back to Staff This Gig", count: 0
  end

  test "pipeline ignores staffing return context for a job outside the owned company" do
    other_company = Company.create!(
      name: "Other Pipeline Co",
      contact_email: "other-pipeline@example.com",
      industries: @company.industries,
      is_public: true
    )
    other_job = other_company.jobs.create!(
      title: "Other Gig",
      posting_type: :multi_position,
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      description: "Other company gig"
    )
    sign_in @owner, scope: :user

    get usr_company_applications_path(@company), params: {
      job_id: other_job.id,
      return_to: "staffing"
    }

    assert_response :success
    assert_select "a", text: "Back to Staff This Gig", count: 0
  end

  test "non-owner cannot view the application pipeline" do
    sign_in @outsider, scope: :user

    get usr_company_applications_path(@company)

    assert_response :not_found
  end

  private

  def create_user(email, first_name: "Pipeline")
    user = User.create!(
      first_name: first_name,
      last_name: "User",
      email: email,
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
