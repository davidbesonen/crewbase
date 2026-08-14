require "test_helper"

class Usr::CrewShortlistsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    @outsider = create_user("outsider")
    @candidate = create_user("candidate").user_profile
    industry = Industry.create!(name: "Shortlist Industry")
    @company = Company.create!(name: "Shortlist Company", contact_email: "shortlist@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    team = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan: team)
  end

  test "starter company cannot access or create shortlists" do
    @company.company_plans.delete_all
    starter = Plan.create!(name: "Starter", key: "starter", monthly_price_cents: 1_900, annual_price_cents: 19_000, active: true, position: 1)
    @company.company_plans.create!(plan: starter)
    sign_in @owner, scope: :user

    get usr_company_crew_shortlists_path(@company)
    assert_redirected_to usr_company_path(@company)

    assert_no_difference("CrewShortlist.count") do
      post usr_company_crew_shortlists_path(@company), params: { crew_shortlist: { name: "Locked List" } }
    end
    assert_redirected_to usr_company_path(@company)
    assert_equal "Shortlists and applicant pipeline requires a Team or Studio plan.", flash[:alert]
  end

  test "company owner creates a named shortlist and adds and removes a profile" do
    sign_in @owner, scope: :user

    assert_difference -> { @company.crew_shortlists.count }, 1 do
      post usr_company_crew_shortlists_path(@company), params: { crew_shortlist: { name: "Tour A-Team" } }
    end
    shortlist = @company.crew_shortlists.last

    assert_difference -> { shortlist.profiles.count }, 1 do
      post usr_crew_shortlist_memberships_path(shortlist), params: { profile_id: @candidate.id }
    end

    assert_difference -> { shortlist.profiles.count }, -1 do
      delete usr_crew_shortlist_membership_path(shortlist, @candidate)
    end
  end

  test "non-owner cannot see or change a company's shortlists" do
    shortlist = @company.crew_shortlists.create!(name: "Private List", created_by: @owner)
    sign_in @outsider, scope: :user

    get usr_company_crew_shortlists_path(@company)
    assert_response :not_found

    sign_in @outsider, scope: :user
    post usr_crew_shortlist_memberships_path(shortlist), params: { profile_id: @candidate.id }
    assert_response :not_found
  end

  test "profile page lets an owner add the person to an owned shortlist" do
    shortlist = @company.crew_shortlists.create!(name: "Profile List", created_by: @owner)
    sign_in @owner, scope: :user

    get usr_profile_path(@candidate)

    assert_response :success
    assert_select "form[action='#{usr_crew_shortlist_memberships_path(shortlist)}'] button", text: /Add to Profile List/
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "User",
      email: "#{label}-shortlists@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
