require "test_helper"

class Usr::StaffingStartComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  test "one company is preselected and show structure choices remain keyboard accessible" do
    company = Company.new(id: 71, name: "Road Crew")
    render_inline Usr::StaffingStartComponent.new(start: StaffingStart.new(company_id: 71, kind: "single"), companies: [ company ], projects_path: "/usr/companies/71/projects")
    assert_selector "input[type='hidden'][name='staffing[company_id]'][value='71']", visible: :all
    assert_no_selector "select[name='staffing[company_id]']"
    assert_selector "input[type='radio'][name='staffing[kind]'][required]", count: 2
    assert_selector "label[for='staffing_kind_single'] input[checked]"
    assert_button "Continue"
    assert_link "Continue An Existing Project", href: "/usr/companies/71/projects"
  end

  test "owners with multiple companies can choose one without losing their event choice" do
    companies = [ Company.new(id: 71, name: "Road Crew"), Company.new(id: 72, name: "Festival Crew") ]
    render_inline Usr::StaffingStartComponent.new(start: StaffingStart.new(company_id: 72, kind: "multi_show"), companies:, projects_path: "/usr/projects/select_company")
    assert_select "Company", selected: "Festival Crew"
    assert_selector "input[id='staffing_kind_multi_show'][checked]"
    assert_text "Start by naming a Project"
  end

  test "invalid choices explain the next action in plain language" do
    start = StaffingStart.new
    start.valid?
    render_inline Usr::StaffingStartComponent.new(start:, companies: [ Company.new(id: 71, name: "Road Crew") ], projects_path: "/usr/companies/71/projects")
    assert_selector "[role='alert']", text: /Choose a company/
    assert_selector "[role='alert']", text: /single gig or a multi-show event/
  end
end
