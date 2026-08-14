require "test_helper"

class Usr::JobCompanySelectionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "David",
      last_name: "Jobs",
      email: "david.jobs@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    sign_in @user, scope: :user

    industry = Industry.create!(name: "Company Selection")
    @first_company = Company.create!(name: "First Company", contact_email: "first-company@example.com", industries: [ industry ])
    @second_company = Company.create!(name: "Second Company", contact_email: "second-company@example.com", industries: [ industry ])
    @other_company = Company.create!(name: "Someone Else's Company", contact_email: "other-company@example.com", industries: [ industry ])
    @first_company.company_assignments.create!(user: @user, role: "owner")
    @second_company.company_assignments.create!(user: @user, role: "owner")
  end

  test "company selector lists the users companies as new job buttons" do
    get "/usr/jobs/select_company"

    assert_response :success
    assert_select "h1", text: "Which company?"
    assert_select "a[href='#{new_usr_company_job_path(@first_company)}']", text: @first_company.name
    assert_select "a[href='#{new_usr_company_job_path(@second_company)}']", text: @second_company.name
    assert_select "a", text: @other_company.name, count: 0
  end
end
