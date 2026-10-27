require "test_helper"

class Usr::Company::CrewRosterUploadComponentTest < ViewComponent::TestCase
  test "upload is prominent and explains review and contact requirements" do
    render_inline Usr::Company::CrewRosterUploadComponent.new(company: Company.new(id: 71, name: "Road Crew"), can_browse: true)
    assert_selector "[data-crew-roster-upload] a.btn-primary[href='/usr/companies/71/crew_imports/new']", text: "Upload Crew Roster"
    assert_selector "a[href='/usr/companies/71/crew_members']", text: "View Crew Roster"
    assert_text "review and edit contacts"
    assert_text "email or phone number"
    assert_text "does not send invitations or create accounts"
  end

  test "employee entry point offers upload without owner-only roster controls" do
    render_inline Usr::Company::CrewRosterUploadComponent.new(company: Company.new(id: 71, name: "Road Crew"), can_browse: false)
    assert_selector "a[href='/usr/companies/71/crew_imports/new']", text: "Upload Crew Roster"
    assert_no_selector "a[href='/usr/companies/71/crew_members']"
  end
end
