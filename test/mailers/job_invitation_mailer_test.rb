require "test_helper"

class JobInvitationMailerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Owner", last_name: "Crew", email: "mail-owner@example.com", password: "password123")
    @recipient = User.create!(first_name: "Worker", last_name: "Crew", email: "mail-recipient@example.com", password: "password123", email_notifications_enabled: false)
    @profile = @recipient.profiles.create!(profile_type: "user", completed_at: Time.current)
    company = Company.create!(name: "Invitations", contact_email: "invitations@example.com", industries: [ Industry.create!(name: "Invitations film") ])
    company.company_assignments.create!(user: @owner, role: :owner)
    @job = company.jobs.create!(title: "Camera Operator", description: "Camera work", employment_type: :contract,
      workplace_type: :on_site, status: :published, is_active: true, starts_at: 2.days.from_now)
  end

  test "email invitations respect an existing recipient email opt out" do
    invitation = JobInvitationCreator.new(job: @job, email: @recipient.email, invited_by: @owner).call
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      JobInvitationMailer.with(invitation:).invite.deliver_now
    end
  end

  test "cancelled or no longer open invitations are not emailed" do
    invitation = JobInvitationCreator.new(job: @job, email: "new-recipient@example.com", invited_by: @owner).call
    @job.update!(status: :closed)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      JobInvitationMailer.with(invitation:).invite.deliver_now
    end
  end
end
