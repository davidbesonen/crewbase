require "test_helper"

class JobOfferWorkflowTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = user("offer-owner")
    @worker = user("offer-worker")
    industry = Industry.create!(name: "Offer industry")
    @company = Company.create!(name: "Offer company", contact_email: "offers@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Camera", description: "Film", status: :published,
      workplace_type: :on_site, employment_type: :contract, starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    @application = @job.job_applications.create!(profile: @worker.user_profile)
    @terms = { role: "Camera operator", starts_at: @job.starts_at, ends_at: @job.ends_at,
      rate: "450", currency: "USD", pay_unit: "daily", terms: "Travel included", expires_at: 2.days.from_now }
  end

  test "offers require a worker response before a booking exists and responses are idempotent" do
    assert defined?(JobOffer), "Job offers must be implemented"
    offer = issue
    assert offer.pending?
    assert_not @application.reload.accepted?
    result = respond(offer, "accept")
    assert result.success?, result.error
    assert offer.reload.accepted?
    assert @application.reload.accepted?
    assert respond(offer, "accept").success?
    assert_not respond(offer, "decline").success?
  end

  test "terms cannot be edited and reissuing withdraws the old pending offer" do
    assert defined?(JobOffer), "Job offers must be implemented"
    first = issue
    assert_not first.update(rate: 1)
    second = issue(rate: "600")
    assert first.reload.withdrawn?
    assert second.pending?
    assert_equal 450, first.rate
    assert_equal 600, second.rate
  end

  test "expired and unauthorized offers cannot be accepted" do
    assert defined?(JobOffer), "Job offers must be implemented"
    offer = issue
    assert_not RespondToJobOffer.new(offer:, user: @owner, action: "accept").call.success?
    travel_to 3.days.from_now do
      assert_not respond(offer, "accept").success?
      assert offer.reload.expired?
    end
    assert_not @application.reload.accepted?
  end

  test "calendar blockouts and existing bookings prevent acceptance" do
    assert defined?(JobOffer), "Job offers must be implemented"
    offer = issue
    @worker.user_profile.calendar_events.create!(provider: :manual, external_id: "blocked", event_type: "blockout", from_date: @job.starts_at.to_date, to_date: @job.ends_at.to_date)
    assert_not respond(offer, "accept").success?
    assert offer.reload.pending?
    @worker.user_profile.calendar_events.destroy_all
    other = @company.jobs.create!(title: "Existing", description: "Booked", status: :published, workplace_type: :on_site, employment_type: :contract, starts_at: @job.starts_at, ends_at: @job.ends_at)
    other.job_applications.create!(profile: @worker.user_profile, status: :accepted)
    assert_not respond(offer, "accept").success?
  end

  test "single role capacity is checked again at acceptance" do
    assert defined?(JobOffer), "Job offers must be implemented"
    offer = issue
    @job.job_applications.create!(profile: user("other-worker").user_profile, status: :accepted)
    assert_not respond(offer, "accept").success?
    assert offer.reload.pending?
  end

  test "cancellation retains agreed terms and records who cancelled" do
    assert defined?(JobOffer), "Job offers must be implemented"
    offer = issue
    assert respond(offer, "accept").success?
    assert RespondToJobOffer.new(offer:, user: @owner, action: "cancel", reason: "Project cancelled").call.success?
    assert offer.reload.cancelled?
    assert_equal @owner, offer.cancelled_by
    assert_equal "Project cancelled", offer.cancellation_reason
    assert_not @application.reload.accepted?
    assert_equal 450, offer.rate
  end

  test "dashboard uses agreed offer dates and ignores pending offers" do
    offer = issue(starts_at: 10.days.from_now, ends_at: 11.days.from_now)
    assert_empty DashboardWorkSchedule.new(profile: @worker.user_profile).booked_jobs
    assert respond(offer, "accept").success?
    booking = DashboardWorkSchedule.new(profile: @worker.user_profile).booked_jobs.sole
    assert_equal offer.starts_at, booking.starts_at
    assert_equal offer.ends_at, booking.ends_at
  end

  test "deleted positions cannot be accepted and filled position capacity is rechecked" do
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Camera", headcount: 1)
    result = IssueJobOffer.new(application: @application, sender: @owner, position:, attributes: @terms).call
    assert result.success?, result.error
    position.crew_assignments.create!(profile: user("filled-position").user_profile)
    assert_not respond(result.offer, "accept").success?
    position.destroy!
    assert_not respond(result.offer.reload, "accept").success?
    assert_not @application.reload.accepted?
  end

  test "new offers reject past work and expired response deadlines" do
    result = IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms.merge(starts_at: 2.days.ago, ends_at: 1.day.ago, expires_at: nil)).call
    assert_not result.success?
    result = IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms.merge(expires_at: 1.minute.ago)).call
    assert_not result.success?
  end

  test "completed work cannot be rewritten through cancellation" do
    offer = issue
    assert respond(offer, "accept").success?
    @job.update!(status: :completed)
    result = RespondToJobOffer.new(offer:, user: @owner, action: "cancel", reason: "Changed my mind").call
    assert_not result.success?
    assert offer.reload.accepted?
  end

  private

  def issue(**overrides)
    result = IssueJobOffer.new(application: @application, sender: @owner, attributes: @terms.merge(overrides)).call
    assert result.success?, result.error
    result.offer
  end

  def respond(offer, action)
    RespondToJobOffer.new(offer:, user: @worker, action:).call
  end

  def user(label)
    value = User.create!(first_name: label, last_name: "Test", email: "#{label}@example.com", password: "password123")
    value.profiles.create!(profile_type: "user", completed_at: Time.current)
    value.visits.create!
    value
  end
end
