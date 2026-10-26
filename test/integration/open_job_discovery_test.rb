require "test_helper"

class OpenJobDiscoveryTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    travel_to Time.zone.local(2026, 9, 27, 12)
    @owner = member("owner")
    @worker = member("worker")
    @worker.user_profile.update!(capability_keys: [ "audio" ])
    @company = Company.create!(name: "Discovery Audio", contact_email: "discovery@example.com",
      industries: [ Industry.create!(name: "Discovery Industry") ], is_public: true)
    @company.company_assignments.create!(user: @owner, role: "owner")
    @open = posting("Open audio role", application_deadline: 1.day.from_now)
    @expired = posting("Expired audio role", application_deadline: 1.second.ago)
    @finished = posting("Finished audio role", starts_at: 2.days.ago, ends_at: 1.day.ago)
    @past_start = posting("Past undated finish", starts_at: 1.day.ago)
    @draft = posting("Draft audio role", status: :draft)
    sign_in @worker, scope: :user
  end

  teardown { travel_back }

  test "open job scope agrees with individual eligibility including date boundaries" do
    today = posting("Today audio role", starts_at: Time.current.beginning_of_day)
    boundary = posting("Deadline now", application_deadline: Time.current)
    inactive = posting("Inactive", is_active: false)
    expected = [ @open, today, boundary ]

    assert_equal expected.map(&:id).sort, Job.accepting_applications.ids.sort
    [ *expected, @expired, @finished, @past_start, @draft, inactive ].each do |job|
      assert_equal expected.include?(job), job.accepting_applications?, job.title
    end
  end

  test "job discovery and worker recommendations omit expired and finished work" do
    get usr_jobs_path
    assert_response :success
    assert_select "a[href='#{usr_job_path(@open)}']", text: @open.title
    [ @expired, @finished, @past_start, @draft ].each do |job|
      assert_select "a[href='#{usr_job_path(job)}']", count: 0
    end
    assert_equal [ @open ], WorkerJobRecommender.new(profile: @worker.user_profile).results.map(&:job)
  end

  test "company listings count only openings still accepting applications" do
    get usr_companies_path
    assert_response :success
    assert_select ".card", text: /1 open job/
    assert_select ".card", text: /5 open jobs/, count: 0
    get usr_company_path(@company)
    assert_select "#company-jobs a[href='#{usr_job_path(@expired)}']", count: 0
    assert_select "#company-jobs a[href='#{usr_job_path(@open)}']"
  end

  test "filtered directories explain no matches and provide a reset" do
    get usr_jobs_path, params: { q: { title_cont: "NoSuchRole" } }
    assert_select "h5", text: "No matching jobs"
    assert_select ".empty-state a[href='#{usr_jobs_path}']", text: "Clear filters"

    get usr_profiles_path, params: { q: { user_first_name_or_user_last_name_cont: "NoSuchPerson" } }
    assert_select ".empty-state a[href='#{usr_profiles_path}']", text: "Clear filters"

    get usr_companies_path, params: { q: { name_cont: "NoSuchCompany" } }
    assert_select ".empty-state a[href='#{usr_companies_path}']", text: "Clear filters"
  end

  test "result summary gives the displayed range and total" do
    get usr_jobs_path
    assert_select "[data-results-summary]", text: "Showing 1–1 of 1 job"
  end

  test "expired postings explain closure and reject direct application submissions" do
    get usr_job_path(@expired)
    assert_response :success
    assert_select "a[href='#{new_usr_job_job_application_path(@expired)}']", count: 0
    assert_select "[data-applications-closed]", text: /Applications closed/

    get new_usr_job_job_application_path(@expired)
    assert_redirected_to usr_job_path(@expired)
    assert_match(/no longer accepting applications/i, flash[:alert])

    assert_no_difference "JobApplication.count" do
      post usr_job_job_applications_path(@expired), params: { job_application: { additional_information: "Interested" } }
    end
    assert_redirected_to usr_job_path(@expired)
  end

  test "public expired postings do not advertise applying or signup to apply" do
    sign_out @worker
    get public_job_posting_path(@expired)
    assert_response :success
    assert_select "[data-applications-closed]", text: /Applications closed/
    assert_select "a", text: /[Aa]pply/, count: 0
  end

  test "profile invitations exclude jobs no longer accepting applications" do
    sign_in @owner, scope: :user
    get usr_profile_path(@worker.user_profile)
    assert_response :success
    assert_select "select[name='job_invitation[job_id]']" do
      assert_select "option[value='#{@open.id}']"
      assert_select "option[value='#{@expired.id}']", count: 0
    end
    assert_no_difference "JobInvitation.count" do
      post usr_profile_job_invitations_path(@worker.user_profile), params: { job_invitation: { job_id: @expired.id } }
    end
    assert_response :not_found
  end

  test "closed postings do not offer owners invitation controls" do
    sign_in @owner, scope: :user
    get usr_job_path(@expired)
    assert_response :success
    assert_select "[data-job-invitation-tools]", count: 0

    get usr_job_path(@open)
    assert_select "[data-job-invitation-tools]"
  end

  test "dashboard open postings exclude expired work" do
    assert_empty CrewRecommender.new(user: @owner, jobs: [ @expired ]).results_for(@expired)
    sign_in @owner, scope: :user
    get usr_dashboards_path
    assert_response :success
    assert_select "[data-owned-job-posting-id='#{@open.id}']"
    assert_select "[data-owned-job-posting-id='#{@expired.id}']", count: 0
  end

  private

  def member(name)
    User.create!(first_name: name, last_name: "Discovery", email: "#{name}-discovery@example.com", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end

  def posting(title, **attributes)
    @company.jobs.create!({ title:, description: "Audio production", status: :published, is_active: true,
      employment_type: :contract, workplace_type: :on_site, required_capability_keys: [ "audio" ] }.merge(attributes))
  end
end
