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
    token = member.invitation_token!
    result = ClaimCrewMember.new(member:, user: @user, token:).call
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
    token = member.invitation_token!
    assert_not ClaimCrewMember.new(member:, user: @user, token:).call.success?
    member.update!(email: @user.email)
    token = member.invitation_token!
    profile = @user.profiles.create!(profile_type: "user", headline: "My own headline", bio: "My biography")
    assert ClaimCrewMember.new(member:, user: @user, token:).call.success?
    assert_equal "My own headline", profile.reload.headline
    assert_equal "My biography", profile.bio
    assert ClaimCrewMember.new(member: member.reload, user: @user, token:).call.success?
  end
  test "revoked or expired invitations are rechecked under the claim lock" do
    member = @company.crew_members.create!(first_name: "Alex", last_name: "Audio", email: @user.email)
    token = member.invitation_token!
    stale_member = CrewMember.find(member.id)
    member.invitation_token!
    assert_no_difference "Profile.count" do
      result = ClaimCrewMember.new(member: stale_member, user: @user, token:).call
      assert_not result.success?
      assert_nil member.reload.profile_id
    end
    token = member.invitation_token!
    travel 8.days do
      assert_no_difference "Profile.count" do
        assert_not ClaimCrewMember.new(member:, user: @user, token:).call.success?
      end
    end
  end

  test "one account claims multiple company rosters without duplicate profiles or shared private history" do
    other = Company.create!(name: "Another Production Company", contact_email: "other-roster@example.com", industries: @company.industries)
    members = [ @company, other ].each_with_index.map do |company, index|
      batch = company.crew_imports.create!(uploaded_by: @user, rows: [])
      result = CrewRosterImport.new(import: batch, rows: [ {
        "first_name" => "Alex", "last_name" => "Audio", "email" => @user.email, "phone" => "6155550177",
        "role" => index.zero? ? "FOH Engineer" : "Monitor Engineer",
        "notes" => "Private history #{index}", "years_with_company" => index + 1
      } ]).call
      assert result.success?, result.error
      company.crew_members.sole
    end
    tokens = members.map(&:invitation_token!)
    assert_difference "Profile.count", 1 do
      assert ClaimCrewMember.new(member: members.first, user: @user, token: tokens.first).call.success?
    end
    profile = @user.user_profile
    assert_no_difference [ "User.count", "Profile.count", "CompanyAssignment.count" ] do
      result = ClaimCrewMember.new(member: members.last, user: @user, token: tokens.last).call
      assert result.success?, result.error
    end
    assert_equal [ profile.id ], members.map { |member| member.reload.profile_id }.uniq
    assert_equal 2, profile.crew_members.count
    assert_equal "FOH Engineer", profile.reload.headline
    assert_equal [ "Private history 0", "Private history 1" ], members.map(&:notes)
    assert_equal [ BigDecimal("1"), BigDecimal("2") ], members.map(&:years_with_company)
    refute_includes profile.attributes.values.join(" "), "Private history"
    duplicate = @company.crew_members.new(first_name: "Duplicate", last_name: "Crew", email: "alternate@example.com", profile:)
    assert_not duplicate.valid?
    assert duplicate.errors[:profile_id].any?
    members.first.destroy!
    assert Profile.exists?(profile.id)
    assert_equal profile.id, members.last.reload.profile_id
    assert_equal 1, profile.crew_members.count
  end
end
