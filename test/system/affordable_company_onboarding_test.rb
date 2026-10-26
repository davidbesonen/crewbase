require "application_system_test_case"

class AffordableCompanyOnboardingTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "a company can start free and review its plan without payment or mobile overflow" do
    InstallPricingCatalog.new.call
    user = User.create!(first_name: "Pricing", last_name: "Tester", email: "pricing-system@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    login_as user, scope: :user

    visit new_usr_company_path
    assert_selector ".company-plan-card", count: 2
    assert_text "$19"
    assert_text "No card required"
    page.save_screenshot("/private/tmp/crewbase-pricing-desktop.png")
    page.driver.browser.manage.window.resize_to(390, 1000)
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/crewbase-pricing-mobile.png")
    click_link "Start free"
    assert_selector "#company_details_form:not(.d-none)"
    assert_no_text "Continue to Payment"
    fill_in "company_name", with: "Affordable Test Productions"
    fill_in "Contact email", with: "producer@example.com"
    fill_in "City", with: "Austin"
    select "United States", from: "Country"
    assert_text "Live Music & Touring"
    assert_no_selector "#company_industry_ids_combobox"
    click_button "Create Company", exact: true
    assert_text "Company created successfully!"
    company = user.owned_companies.find_by!(name: "Affordable Test Productions")
    assert_equal [ "Live Music & Touring" ], company.industries.pluck(:name)
    assert_equal "free", CompanyPlanEntitlement.new(company).tier
    visit usr_company_applications_path(company)
    assert_text "Application Pipeline"
    visit usr_company_plan_path(company)
    assert_text "Free · no card required"
    assert_text "Paid upgrades are not available yet"
    assert_no_button "Continue to secure checkout"
  ensure
    Warden.test_reset!
  end
end
