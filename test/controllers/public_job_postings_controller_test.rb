require "test_helper"

class PublicJobPostingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    industry = Industry.create!(name: "Public Postings")
    @company = Company.create!(
      name: "Open Door Productions",
      contact_email: "jobs@open-door.example",
      industries: [ industry ]
    )
    @job = Job.create!(
      company: @company,
      title: "Touring Lighting Technician",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Travel with the lighting team."
    )
  end

  test "signed-in owner does not see an apply action on the public posting" do
    owner = User.create!(
      first_name: "Posting",
      last_name: "Owner",
      email: "public-posting-owner@example.com",
      password: "password123"
    )
    @company.company_assignments.create!(user: owner, role: "owner")
    sign_in owner, scope: :user

    get public_job_posting_path(@job)

    assert_response :success
    assert_select "a[href='#{new_usr_job_job_application_path(@job)}']", count: 0
    assert_select "*", text: /You manage this posting/
  end

  test "anyone can view and copy an open posting link" do
    get public_job_posting_path(@job)

    assert_response :success
    assert_select "h1", text: @job.title
    assert_select "a[href*='sign_up']", text: /create.*account/i
    assert_select "a[href*='sign_in']", text: /sign in/i
  end

  test "unpublished postings are not public" do
    @job.update!(status: :draft)

    get public_job_posting_path(@job)

    assert_response :not_found
  end
end
