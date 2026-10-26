require "test_helper"

class JobOfferBlockingTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner, @worker = %w[owner worker].map do |name|
      user = User.create!(first_name: name, last_name: "Blocked Offers", email: "offer-block-#{name}@example.com", password: "password123")
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user
    end
    company = Company.create!(name: "Blocked Offers", contact_email: "blocked-offers@example.com", industries: [ Industry.create!(name: "Blocked Offers") ])
    company.company_assignments.create!(user: @owner, role: "owner")
    @job = company.jobs.create!(title: "Blocked Offer Job", description: "Crew", workplace_type: :on_site, employment_type: :contract, status: :published, starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    @application = @job.job_applications.create!(profile: @worker.user_profile)
    @terms = { role: "Camera operator", starts_at: @job.starts_at, ends_at: @job.ends_at, rate: "450", currency: "USD", pay_unit: "daily" }
  end

  test "new offers cannot contact a blocked account in either direction" do
    block = UserBlock.create!(blocker: @worker, blocked_user: @owner)
    assert_no_difference [ "JobOffer.count", "Notification.count" ] do
      result = IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms).call
      assert_not result.success?
      assert_match(/not available for new offers/, result.error)
    end
    block.destroy!
    UserBlock.create!(blocker: @owner, blocked_user: @worker)
    assert_no_difference "JobOffer.count" do
      assert_not IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms).call.success?
    end
  end

  test "blocking prevents direct crew offers but preserves existing booking cancellation" do
    offer = IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms).call.offer
    assert RespondToJobOffer.new(offer: offer, user: @worker, action: "accept").call.success?
    UserBlock.create!(blocker: @worker, blocked_user: @owner)
    message = ContextualMessageCreator.new(context: @application, sender: @worker, body: "Confirming our existing call").call
    assert message.persisted?
    result = RespondToJobOffer.new(offer: offer, user: @worker, action: "cancel", reason: "Cannot attend").call
    assert result.success?, result.error
    assert offer.reload.cancelled?
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Camera", headcount: 1)
    assert_no_difference "JobOffer.count" do
      result = IssueJobOffer.new(application: @application, sender: @owner, position: position, attributes: @terms).call
      assert_not result.success?
    end
  end
end
