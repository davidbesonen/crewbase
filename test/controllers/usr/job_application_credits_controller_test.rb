require "test_helper"

class Usr::JobApplicationCreditsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "workers cannot manually add an accepted job as a credit" do
    worker = User.create!(
      first_name: "Verified",
      last_name: "Worker",
      email: "verified-credit-worker@example.com",
      password: "password123"
    )
    profile = worker.profiles.create!(profile_type: "user", completed_at: Time.current)
    worker.visits.create!
    owner = User.create!(
      first_name: "Hiring",
      last_name: "Owner",
      email: "verified-credit-owner@example.com",
      password: "password123"
    )
    industry = Industry.create!(name: "Verified Credits")
    company = Company.create!(
      name: "Verified Production",
      contact_email: "verified-production@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    project = company.projects.create!(name: "City Festival")
    job = company.jobs.create!(
      project: project,
      title: "Lighting Designer",
      description: "Design the festival lighting.",
      employment_type: :contract,
      workplace_type: :on_site,
      status: :filled,
      is_active: false,
      starts_at: Time.zone.local(2026, 7, 18),
      ends_at: Time.zone.local(2026, 7, 20),
      filled_at: Time.current
    )
    application = job.job_applications.create!(
      profile: profile,
      status: :accepted,
      decision_at: Time.current
    )
    sign_in worker, scope: :user

    assert_no_difference "profile.credits.count" do
      post add_credit_usr_job_application_path(application)
    end
    assert_response :not_found
  end
end
