require "test_helper"

class Usr::SavedJobsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = create_user("worker")
    @other_user = create_user("other")
    industry = Industry.create!(name: "Saved Job Industry")
    company = Company.create!(name: "Saved Job Company", contact_email: "saved@example.com", industries: [ industry ])
    @job = company.jobs.create!(
      title: "Saved Touring Role",
      description: "Tour with the production.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true
    )
    sign_in @user, scope: :user
  end

  test "saves and unsaves a job for the current user" do
    assert_difference -> { @user.saved_jobs.count }, 1 do
      post usr_job_saved_job_path(@job)
    end
    assert_redirected_to usr_job_path(@job)

    assert_difference -> { @user.saved_jobs.count }, -1 do
      delete usr_job_saved_job_path(@job)
    end
    assert_redirected_to usr_job_path(@job)
  end

  test "saved jobs index only lists the current user's jobs" do
    @user.saved_jobs.create!(job: @job)
    other_job = @job.company.jobs.create!(
      title: "Someone Else's Saved Role",
      description: "A different saved role.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true
    )
    @other_user.saved_jobs.create!(job: other_job)

    get usr_saved_jobs_path

    assert_response :success
    assert_select "h1", text: "Saved Jobs"
    assert_select "a.btn-primary[href='#{usr_jobs_path}']", text: "Browse Jobs"
    assert_select "a", text: @job.title
    assert_select "a", text: other_job.title, count: 0
  end

  test "empty saved jobs offers browsing as the primary action" do
    get usr_saved_jobs_path

    assert_response :success
    assert_select "a.btn-primary[href='#{usr_jobs_path}']", text: "Browse Jobs"
  end

  test "closed saved jobs remain removable without exposing a dead job link" do
    @user.saved_jobs.create!(job: @job)
    other_save = @other_user.saved_jobs.create!(job: @job)
    @job.update!(status: :closed)
    get usr_saved_jobs_path
    assert_response :success
    assert_select "a[href='#{usr_job_path(@job)}']", count: 0
    assert_select "[data-saved-job='#{@job.id}']", text: /No longer accepting applications/
    delete usr_job_saved_job_path(@job)
    assert_redirected_to usr_saved_jobs_path
    assert_not @user.saved_jobs.exists?(job: @job)
    assert SavedJob.exists?(other_save.id)
  end

  test "saved jobs filter distinguishes open jobs from unavailable postings" do
    @user.saved_jobs.create!(job: @job)
    @job.update!(application_deadline: 1.day.ago)
    get usr_saved_jobs_path, params: { status: "open" }
    assert_select "[data-saved-job]", count: 0
    assert_select "a", text: "Show all saved jobs"
    get usr_saved_jobs_path, params: { status: "unavailable" }
    assert_select "[data-saved-job='#{@job.id}']"
  end

  test "cannot save closed jobs or remove another user's saved job" do
    @other_user.saved_jobs.create!(job: @job)
    @job.update!(status: :closed)
    post usr_job_saved_job_path(@job)
    assert_response :not_found
    sign_in @user
    delete usr_job_saved_job_path(@job)
    assert_response :not_found
    assert @other_user.saved_jobs.exists?(job: @job)
  end

  test "job page offers save and remove actions" do
    get usr_job_path(@job)
    assert_select "form[action='#{usr_job_saved_job_path(@job)}'] button", text: "Save Job"

    @user.saved_jobs.create!(job: @job)
    get usr_job_path(@job)
    assert_select "form[action='#{usr_job_saved_job_path(@job)}'] button", text: "Saved"
  end

  test "expired job page does not offer a save action that will fail" do
    @job.update!(application_deadline: 1.day.ago)
    get usr_job_path(@job)
    assert_select "button", text: "Save Job", count: 0
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "User",
      email: "#{label}-saved-jobs@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
