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
    assert_select "a", text: @job.title
    assert_select "a", text: other_job.title, count: 0
  end

  test "job page offers save and remove actions" do
    get usr_job_path(@job)
    assert_select "form[action='#{usr_job_saved_job_path(@job)}'] button", text: "Save Job"

    @user.saved_jobs.create!(job: @job)
    get usr_job_path(@job)
    assert_select "form[action='#{usr_job_saved_job_path(@job)}'] button", text: "Saved"
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
