require "test_helper"

class Usr::Company::ManagerToolsComponentTest < ViewComponent::TestCase
  test "management links have clear names and descriptions without a paid analytics prompt" do
    render_inline Usr::Company::ManagerToolsComponent.new(company: Company.new(id: 71, name: "Road Crew"), analytics_available: true)

    assert_selector "h1", text: "Road Crew Company Manager"
    assert_selector "[data-company-management-tools] a", count: 5
    assert_selector "a[href='/usr/companies/71/venues']", text: /Venues.*Manage saved venues/m
    assert_selector "a[href='/usr/companies/71/plan']", text: /Plan & Billing/
    assert_no_selector "[data-analytics-upgrade]"
  end

  test "owners without analytics can still access every management tool" do
    render_inline Usr::Company::ManagerToolsComponent.new(company: Company.new(id: 71, name: "Road Crew"), analytics_available: false)

    assert_selector "[data-company-management-tools] a", count: 5
    assert_selector "[data-analytics-upgrade] a", text: "Compare Plans"
  end
end
