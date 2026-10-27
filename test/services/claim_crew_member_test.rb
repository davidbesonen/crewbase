require "test_helper"

class ClaimCrewMemberTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Alex", last_name: "Audio", email: "claim-alex@example.com", password: "password123")
    @company = Company.create!(name: "Claim Productions", contact_email: "claim-owner@example.com", industries: [ Industry.music_touring! ])
  end

  test "claim creates a real profile from imported details without exposing private notes" do
    assert defined?(ClaimCrewMember), "Crew need a secure way to finish their imported profile"
    member = @company.crew_members.create!(first_name: "Alex", last_name: "Audio", email: @user.email, role: "FOH Engineer", city: "Austin", state: "TX", equipment_text: "DiGiCo", notes: "Owner's private note", years_with_company: 5)
    result = ClaimCrewMember.new(member:, user: @user).call
    assert result.success?, result.error
    assert_equal @user.user_profile, member.reload.profile
    assert_equal "FOH Engineer", @user.user_profile.headline
    assert_equal "Austin", @user.user_profile.primary_location.city
    assert_equal "DiGiCo", @user.user_profile.equipment_text
    assert_nil @user.user_profile.completed_at
    assert_not_includes @user.user_profile.attributes.values.join(" "), "Owner's private note"
  end

  test "a different email cannot claim a contact and existing profiles are not overwritten" do
    assert defined?(ClaimCrewMember), "Claims must check the invited contact"
    member = @company.crew_members.create!(first_name: "Another", last_name: "Person", email: "other@example.com")
    assert_not ClaimCrewMember.new(member:, user: @user).call.success?
    member.update!(email: @user.email)
    profile = @user.profiles.create!(profile_type: "user", headline: "My own headline", bio: "My biography")
    assert ClaimCrewMember.new(member:, user: @user).call.success?
    assert_equal "My own headline", profile.reload.headline
    assert_equal "My biography", profile.bio
    assert ClaimCrewMember.new(member: member.reload, user: @user).call.success?
  end
end
