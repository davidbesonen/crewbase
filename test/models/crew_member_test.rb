require "test_helper"

class CrewMemberTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @company = Company.create!(name: "Contact Validation", contact_email: "contact-audit@example.com", industries: [ Industry.music_touring! ])
  end

  test "names and at least one valid contact are required" do
    [ {}, { email: "bad-email" }, { phone: "12" }, { phone: "letters6155550199" }, { phone: "6155550199 ext 9" } ].each do |contact|
      member = @company.crew_members.new(first_name: "Test", last_name: "Crew", **contact)
      assert_not member.valid?, "Invalid contact was accepted: #{contact.inspect}"
    end
    [ { email: "valid@example.com" }, { phone: "+1 (615) 555-0199" }, { phone: "+44 7700 900123" } ].each do |contact|
      assert @company.crew_members.new(first_name: "Test", last_name: "Crew", **contact).valid?
    end
    assert_not @company.crew_members.new(email: "name-missing@example.com").valid?
  end

  test "email and phone duplicates normalize within a company but remain private across companies" do
    member = @company.crew_members.create!(first_name: "Test", last_name: "Crew", email: " TEST@EXAMPLE.COM ", phone: "6155550199")
    assert_equal "test@example.com", member.email
    assert_equal "16155550199", member.phone_key
    assert_not @company.crew_members.new(first_name: "Duplicate", last_name: "Email", email: "test@example.com").valid?
    assert_not @company.crew_members.new(first_name: "Duplicate", last_name: "Phone", phone: "+1-615-555-0199").valid?
    other = Company.create!(name: "Other Contact Co", contact_email: "other-contact@example.com", industries: @company.industries)
    assert other.crew_members.new(first_name: "Same", last_name: "Person", email: member.email, phone: member.phone).valid?
  end
end
