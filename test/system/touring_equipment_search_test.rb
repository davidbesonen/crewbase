require "application_system_test_case"

class TouringEquipmentSearchTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "crew save named console experience and a company owner finds its common name" do
    programmer = member("Lighting", "Programmer")
    profile = programmer.user_profile
    profile.occupations << Occupation.find_or_create_by!(name: "Lighting Programmer")
    profile.locations.create!(city: "Nashville", state: "TN", country: "United States")
    owner = member("Tour", "Owner")
    company = Company.create!(name: "Touring Search Co", contact_email: "touring-search@example.com", industries: [ Industry.music_touring! ])
    company.company_assignments.create!(user: owner, role: "owner")
    previous = member("Previous", "Console").user_profile
    previous.update!(equipment_text: "grandMA2", equipment_family_keys: [ "lighting_consoles" ])

    login_as programmer, scope: :user
    visit edit_usr_profile_path(profile, source: "completed_profile")
    assert_text "What do you do on tour?"
    assert_no_selector "[role='option']", text: "Actor", visible: :all
    assert_no_selector "input[value='learning_platforms']", visible: :all
    assert_text "Company owners can search these names when hiring"
    fill_in "profile_equipment_text", with: "grand MA 3 full-size"
    click_button "Save Profile"
    assert_text "Profile updated!"
    assert_equal "grand MA 3 full-size", profile.reload.equipment_text

    logout(:user)
    login_as owner, scope: :user
    visit usr_profiles_path(equipment_query: "MA3")
    assert_link programmer.full_name, href: usr_profile_path(profile)
    assert_no_link previous.user.full_name, href: usr_profile_path(previous)
    page.save_screenshot("/private/tmp/crewbase-touring-ma3-search.png")
    visit new_usr_company_path(current_page: "company_details_form")
    assert_selector "[data-touring-industry]", text: "Live Music & Touring"
    assert_no_selector "#company_industry_ids_combobox"
  ensure
    Warden.test_reset!
  end

  private

  def member(first, last)
    User.create!(first_name: first, last_name: last, email: "#{first.downcase}-#{last.downcase}@touring-search.test", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end
end
