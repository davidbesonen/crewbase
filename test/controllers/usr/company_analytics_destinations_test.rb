require "test_helper"

class Usr::CompanyAnalyticsDestinationsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = user("analytics-owner@example.com")
    @coowner = user("analytics-coowner@example.com")
    @company = Company.create!(name: "Analytics Company", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    [ @owner, @coowner ].each { |owner| @company.company_assignments.create!(user: owner, role: "owner") }
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
    sign_in @owner
  end

  test "active job and project destinations show exactly the matching metric records" do
    job("Upcoming Active", status: :published)
    job("Draft Hidden", status: :draft)
    job("Ended Hidden", status: :published).update_columns(ends_at: 2.days.ago)
    get usr_company_jobs_path(@company, view: "active")
    assert_response :success
    assert_select "h4", text: "Upcoming Active"
    assert_select "h4", text: /Hidden/, count: 0
    @company.projects.create!(name: "Planning Run", status: :planning)
    @company.projects.create!(name: "Completed Hidden", status: :completed)
    get usr_company_projects_path(@company, view: "active")
    assert_response :success
    assert_select "h4", text: "Planning Run"
    assert_select "h4", text: "Completed Hidden", count: 0
  end

  test "pending invitations include other owners sends but exclude other companies and statuses" do
    posting = job("Company Gig", status: :published)
    pending = posting.job_invitations.create!(invited_by: @coowner, email: "pending-analytics@example.com")
    accepted = posting.job_invitations.create!(invited_by: @owner, email: "accepted-analytics@example.com", status: :accepted)
    other = Company.create!(name: "Other Analytics", contact_email: @owner.email, industries: @company.industries)
    other.company_assignments.create!(user: @owner, role: "owner")
    other_job = other.jobs.create!(title: "Other Gig", description: "Other staffing test", employment_type: :contract, workplace_type: :on_site)
    unrelated = other_job.job_invitations.create!(invited_by: @owner, email: "other-analytics@example.com")
    get usr_job_invitations_path(company_id: @company.id, status: "pending")
    assert_response :success
    assert_select "[data-sent-invitation='#{pending.id}']"
    assert_select "[data-sent-invitation='#{accepted.id}']", count: 0
    assert_select "[data-sent-invitation='#{unrelated.id}']", count: 0
    assert_select "[data-received-invitation]", count: 0
    sign_in @coowner
    get usr_job_invitations_path(company_id: other.id, status: "pending")
    assert_response :not_found
  end

  private

  def user(email)
    User.create!(first_name: "Analytics", last_name: "Owner", email:, password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.roles << Role.find_or_create_by!(name: "user")
      user.visits.create!
    end
  end

  def job(title, status:)
    @company.jobs.create!(title:, description: "A staffing test", status:, is_active: true, starts_at: 3.days.from_now, employment_type: :contract, workplace_type: :on_site)
  end
end
