require "test_helper"

class JobOffersTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = make_user("offer-ui-owner")
    @worker = make_user("offer-ui-worker")
    industry = Industry.create!(name: "Offer UI")
    @company = Company.create!(name: "Offer UI", contact_email: "offer-ui@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Camera", description: "Film", status: :published, workplace_type: :on_site,
      employment_type: :contract, starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    @application = @job.job_applications.create!(profile: @worker.user_profile)
  end

  test "owner reviews terms and worker explicitly confirms booking" do
    sign_in @owner
    patch update_status_usr_job_application_path(@application), params: { status: "accepted" }
    assert_not @application.reload.accepted?, "Employer decisions must not book workers silently"
    assert_redirected_to new_usr_job_offer_path(job_application_id: @application.id)
    get new_usr_job_offer_path(job_application_id: @application.id)
    assert_response :success
    assert_select ".input-group" do
      assert_select "span.input-group-text", text: "$"
      assert_select "span.input-group-text + input[name='job_offer[rate]'][type='number']"
    end
    post usr_job_offers_path, params: { job_application_id: @application.id, job_offer: {
      role: "Camera operator", starts_at: @job.starts_at, ends_at: @job.ends_at, rate: "400", currency: "USD", pay_unit: "daily"
    } }
    offer = @application.job_offers.sole
    assert_redirected_to usr_job_offer_path(offer)
    sign_out @owner
    sign_in @worker
    get usr_job_offer_path(offer)
    assert_response :success
    assert_select "button", text: /Accept offer/
    patch usr_job_offer_path(offer), params: { decision: "accept" }
    assert @application.reload.accepted?
  end

  test "outsiders cannot inspect or answer offers" do
    offer = IssueJobOffer.new(application: @application, sender: @owner, attributes: {
      role: "Camera", starts_at: @job.starts_at, ends_at: @job.ends_at, rate: 300, currency: "USD", pay_unit: "daily"
    }).call.offer
    outsider = make_user("outsider")
    sign_in outsider
    get usr_job_offer_path(offer)
    assert_response :not_found
    sign_in outsider
    patch usr_job_offer_path(offer), params: { decision: "accept" }
    assert_response :not_found
  end

  test "review status changes cannot silently cancel a confirmed booking" do
    result = IssueJobOffer.new(application: @application, sender: @owner, attributes: {
      role: "Camera", starts_at: @job.starts_at, ends_at: @job.ends_at, rate: 300, currency: "USD", pay_unit: "daily"
    }).call
    assert RespondToJobOffer.new(offer: result.offer, user: @worker, action: "accept").call.success?
    sign_in @owner
    patch update_status_usr_job_application_path(@application), params: { status: "rejected" }
    assert @application.reload.accepted?
    assert_match /cancel/i, flash[:alert]
  end

  test "invalid direct offers leave no phantom application" do
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Camera", headcount: 1)
    @application.destroy!
    shortlist = @company.crew_shortlists.create!(name: "Candidates", created_by: @owner)
    shortlist.crew_shortlist_memberships.create!(profile: @worker.user_profile)
    sign_in @owner
    assert_no_difference "JobApplication.count" do
      post usr_job_offers_path, params: { crew_position_id: position.id, profile_id: @worker.user_profile.id,
        job_offer: { role: "Camera", rate: "", currency: "EUR", pay_unit: "daily" } }
    end
    assert_response :unprocessable_entity
    assert_select "input[name='job_offer[currency]'][value='EUR']"
    assert_select "[data-currency-prefix-target='symbol']", text: "EUR"
  end

  test "offer inbox separates action required confirmed and history with search and expiry ordering" do
    later = create_offer(role: "Later response", expires_at: 2.days.from_now)
    sooner = create_offer(role: "Urgent camera", expires_at: 1.day.from_now)
    expired = create_offer(role: "Old proposal")
    expired.update_columns(expires_at: 1.minute.ago)
    confirmed = create_offer(role: "Confirmed camera", status: :accepted)
    sign_in @worker
    get usr_job_offers_path, params: { view: "needs_reply" }
    assert_response :success
    assert_select "[data-offer-id]", count: 2
    assert_equal [ sooner.id.to_s, later.id.to_s ], css_select("[data-offer-id]").map { |node| node["data-offer-id"] }
    assert_select "a[aria-current='page']", text: /Needs your reply/
    get usr_job_offers_path, params: { view: "confirmed", q: "CONFIRMED" }
    assert_select "[data-offer-id='#{confirmed.id}']"
    assert_select "[data-offer-id]", count: 1
    get usr_job_offers_path, params: { view: "history" }
    assert_select "[data-offer-id='#{expired.id}']", text: /Expired/
    assert_select "[data-offer-id]", count: 1
    sign_out @worker
    sign_in @owner
    get usr_job_offers_path, params: { view: "needs_reply" }
    assert_select "[data-offer-id]", count: 0
    get usr_job_offers_path, params: { view: "sent" }
    assert_select "[data-offer-id]", count: 2
  end

  test "offer inbox never reveals another user's offers even when searched" do
    offer = create_offer(role: "Private camera offer")
    sign_in make_user("inbox-outsider")
    get usr_job_offers_path, params: { view: "all", q: "Private" }
    assert_response :success
    assert_select "a[href='#{usr_job_offer_path(offer)}']", count: 0
    assert_select "[data-offer-id]", count: 0
    assert_select "[data-offer-count]", text: "0", count: 5
  end

  test "dashboard surfaces pending offers but excludes expired proposals" do
    offer = create_offer
    expired = create_offer(role: "Expired proposal")
    expired.update_columns(expires_at: 1.hour.ago)
    sign_in @worker
    get usr_dashboards_path
    assert_select "[data-offers-needing-reply]" do
      assert_select "a[href='#{usr_job_offer_path(offer)}']"
      assert_select "a[href='#{usr_job_offer_path(expired)}']", count: 0
    end
  end

  test "calendar download uses agreed times and is restricted to booking participants" do
    offer = create_offer(status: :accepted, starts_at: 7.days.from_now.change(usec: 0), ends_at: 8.days.from_now.change(usec: 0), role: "Camera, B; unit\nSecond line")
    sign_in @worker
    get "/usr/job_offers/#{offer.id}/calendar"
    assert_response :success
    assert_equal "text/calendar", response.media_type
    assert_match /attachment/, response.headers["Content-Disposition"]
    events = Icalendar::Calendar.parse(response.body).sole.events
    assert_equal 1, events.size
    assert_equal offer.starts_at.utc.to_i, events.sole.dtstart.to_time.to_i
    assert_equal offer.ends_at.utc.to_i, events.sole.dtend.to_time.to_i
    assert_includes events.sole.summary.to_s, offer.role
    assert_equal "PRIVATE", events.sole.ip_class.to_s
    uid = events.sole.uid
    sign_out @worker
    sign_in @owner
    get "/usr/job_offers/#{offer.id}/calendar"
    assert_response :success
    assert_equal uid, Icalendar::Calendar.parse(response.body).sole.events.sole.uid
    sign_out @owner
    sign_in make_user("calendar-outsider")
    get "/usr/job_offers/#{offer.id}/calendar"
    assert_response :not_found
  end

  test "unconfirmed or cancelled offers cannot be exported as bookings" do
    offer = create_offer
    sign_in @worker
    get "/usr/job_offers/#{offer.id}/calendar"
    assert_response :not_found
    offer.update!(status: :cancelled)
    sign_in @worker
    get "/usr/job_offers/#{offer.id}/calendar"
    assert_response :not_found
  end

  test "ended and archived proposals cannot appear as actionable or upcoming" do
    ended = create_offer
    ended.update_columns(starts_at: 2.days.ago, ends_at: 1.day.ago)
    archived = create_offer
    archived.job.update!(status: :archived)
    completed = create_offer(status: :accepted)
    completed.update_columns(starts_at: 2.days.ago, ends_at: 1.day.ago)
    sign_in @worker
    get usr_job_offers_path, params: { view: "needs_reply" }
    assert_select "[data-offer-id]", count: 0
    get usr_job_offers_path, params: { view: "confirmed" }
    assert_select "[data-offer-id]", count: 0
    get usr_job_offers_path, params: { view: "history" }
    assert_select "[data-offer-id]", count: 3
    assert_select "[data-offer-id='#{ended.id}']", text: /Expired/
    assert_select "[data-offer-id='#{archived.id}']", text: /Unavailable/
    assert_select "[data-offer-id='#{completed.id}']", text: /Completed/
    get usr_job_offers_path, params: { view: "bogus", q: "%" }
    assert_response :success
    assert_select "[data-offer-id]", count: 0
  end

  private

  def create_offer(**attributes)
    job = @company.jobs.create!(title: "Offer role", description: "Film", status: :published, workplace_type: :on_site,
      employment_type: :contract, starts_at: @job.starts_at, ends_at: @job.ends_at)
    application = job.job_applications.create!(profile: @worker.user_profile)
    application.job_offers.create!({ profile: @worker.user_profile, sender: @owner, role: "Camera operator",
      starts_at: @job.starts_at, ends_at: @job.ends_at, rate: 400, currency: "USD", pay_unit: "daily" }.merge(attributes))
  end

  def make_user(label)
    user = User.create!(first_name: label, last_name: "Test", email: "#{label}@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
