require "test_helper"

class AcceptJobApplicationTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "employer acceptance cannot bypass explicit offer terms and worker confirmation" do
    owner = User.create!(first_name: "Owner", last_name: "Test", email: "accept-owner@example.com", password: "password123")
    worker = User.create!(first_name: "Worker", last_name: "Test", email: "accept-worker@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user")
    industry = Industry.create!(name: "Acceptance Service")
    company = Company.create!(name: "Acceptance", contact_email: "accept@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(title: "Camera", description: "Film", status: :published, workplace_type: :on_site, employment_type: :contract)
    application = job.job_applications.create!(profile:)
    assert_not AcceptJobApplication.new(application:, reviewer: owner).call.success?
    assert application.reload.submitted?
    result = AcceptJobApplication.new(application:, reviewer: owner, attributes: { role: "Camera", starts_at: 3.days.from_now, ends_at: 4.days.from_now, rate: 400, currency: "USD", pay_unit: "daily" }).call
    assert result.success?, result.error
    assert result.offer.pending?
    assert_not application.reload.accepted?
  end
end
