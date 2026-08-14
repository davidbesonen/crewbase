require "test_helper"

class Usr::JobsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    @outsider = create_user("outsider")
    @industry = Industry.create!(name: "Owner Posting Index")
    @owned_company = create_company("Owned Company", @owner)
    @other_company = create_company("Other Company", @outsider)
  end

  test "owner postings index is scoped to companies the current user owns" do
    owned_job = create_job(@owned_company, "Owned Open Job")
    create_job(@other_company, "Other Owner Job")
    draft_job = create_job(@owned_company, "Owned Draft Job", status: :draft)
    sign_in @owner, scope: :user

    get my_postings_usr_jobs_path

    assert_response :success
    assert_select "h1", text: "My Job Postings"
    assert_select "a[href='#{usr_job_path(owned_job)}']", text: owned_job.title
    assert_select "a", text: "Other Owner Job", count: 0
    assert_select "a[href='#{usr_job_path(draft_job)}']", text: draft_job.title
    assert_select "a[href='#{edit_usr_company_job_path(@owned_company, owned_job)}']", text: "Edit"
    assert_select ".card-accent.card-accent-sky", minimum: 1
    assert_select ".status-badge.status-open", text: "Published"
    assert_select ".status-badge.status-draft", text: "Draft"
  end

  test "users who do not own a company cannot access the owner postings index" do
    sign_in create_user("nonowner"), scope: :user

    get my_postings_usr_jobs_path

    assert_response :not_found
  end

  test "owner postings index explains when the owner has no postings" do
    sign_in @owner, scope: :user

    get my_postings_usr_jobs_path

    assert_response :success
    assert_select "h5", text: "No Job Postings Yet"
    assert_select "p", text: "Post a job for one of your companies to start finding crew."
    assert_select ".empty-state.empty-state-sky"
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "User",
      email: "#{label}-jobs-controller@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end

  def create_company(name, owner)
    company = Company.create!(
      name:,
      contact_email: "#{name.parameterize}@example.com",
      industries: [ @industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    company
  end

  def create_job(company, title, status: :published)
    company.jobs.create!(
      title:,
      description: "Manage this production.",
      workplace_type: :hybrid,
      employment_type: :contract,
      status:,
      is_active: true,
      published_at: Time.current
    )
  end
end
