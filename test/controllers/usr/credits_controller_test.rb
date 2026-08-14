require "test_helper"

class Usr::CreditsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Credit",
      last_name: "Owner",
      email: "credit-owner@example.com",
      password: "password123"
    )
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in @user, scope: :user
  end

  test "profile owner cannot manually create a Crewbase Credit" do
    assert_no_difference "@profile.credits.count" do
      post usr_profile_credits_path(@profile), params: {
        credit: {
          role: "Audio Engineer",
          project_name: "One Night Live",
          company_name: "Outside Client",
          starts_on: "2026-07-20",
          ends_on: "2026-07-20",
          location: "Milwaukee, WI",
          description: "Mixed the live broadcast.",
          verified_at: Time.current,
          job_id: 123
        }
      }
    end
    assert_response :not_found
  end

  test "profile owner cannot change or remove verified credit details" do
    credit = @profile.credits.create!(role: "Operator", project_name: "Private Gig")

    patch usr_profile_credit_path(@profile, credit), params: {
      credit: { role: "Changed" }
    }
    assert_response :not_found
    assert_equal "Operator", credit.reload.role

    assert_no_difference "@profile.credits.count" do
      delete usr_profile_credit_path(@profile, credit)
    end
    assert_response :not_found
  end

  test "profile owner can hide an individual credit without changing its details" do
    credit = @profile.credits.create!(role: "Operator", project_name: "Arena Show")

    patch usr_profile_credit_path(@profile, credit), params: { credit: { visible: false } }

    assert_redirected_to edit_usr_profile_path(@profile, source: "completed_profile", anchor: "credits_form")
    assert_not credit.reload.visible?
    assert_equal "Operator", credit.role
  end
end
