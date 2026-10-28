require "test_helper"

class Usr::Company::EmployeesTabComponentTest < ViewComponent::TestCase
  test "company team distinguishes access memberships from roster contacts" do
    user = User.new(first_name: "Alex", last_name: "Owner")
    assignments = [ CompanyAssignment.new(user:, role: "owner"), CompanyAssignment.new(user:, role: "member") ]
    render_inline Usr::Company::EmployeesTabComponent.new(company: Company.new, assignments:)
    assert_selector "h5", text: "2 Company Users"
    assert_text "Owner"
    assert_text "Employee"
    assert_text "Crew roster contacts are managed separately"
  end
end
