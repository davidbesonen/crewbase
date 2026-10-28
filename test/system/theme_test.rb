require "application_system_test_case"

class ThemeTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "appearance follows the system and remembers explicit choices across pages and reloads" do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-color-scheme", value: "dark" } ])
    visit new_user_session_path
    page.execute_script("localStorage.removeItem('crewbase.theme')")
    visit new_user_session_path
    assert_selector "html[data-bs-theme='dark']"
    assert_no_selector "[data-theme-choice]"
    user = User.create!(first_name: "Theme", last_name: "Crew", email: "theme-crew@example.com", password: "password123")
    user.roles << Role.find_or_create_by!(name: "user")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    login_as user, scope: :user
    visit usr_settings_path
    assert_select_theme "system"
    select "Light", from: "Appearance"
    assert_selector "html[data-bs-theme='light']"
    page.refresh
    assert_selector "html[data-bs-theme='light']"
    select "Dark", from: "Appearance"
    visit welcome_path
    assert_selector "html[data-bs-theme='dark']"
    assert_no_selector "[data-theme-choice]"
    visit usr_settings_path
    assert_select_theme "dark"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/crewbase-dark-home.png")
    select "System", from: "Appearance"
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-color-scheme", value: "light" } ])
    assert_selector "html[data-bs-theme='light']"
  ensure
    page.execute_script("localStorage.removeItem('crewbase.theme')")
    Warden.test_reset!
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  test "dark mode covers admin records forms and the workspace on mobile" do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
    user = User.create!(first_name: "Theme", last_name: "Owner", email: "theme-system@example.com", password: "password123")
    user.roles << Role.find_or_create_by!(name: "app_owner")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    login_as user, scope: :user
    visit usr_settings_path
    select "Dark", from: "Appearance"
    visit admin_users_path
    click_link user.full_name
    assert_selector "textarea"
    assert_selector "html[data-bs-theme='dark']"
    assert_equal "rgb(17, 24, 39)", page.evaluate_script("getComputedStyle(document.querySelector('.card')).backgroundColor")
    assert_equal "rgb(9, 13, 22)", page.evaluate_script("getComputedStyle(document.querySelector('textarea')).backgroundColor")
    page.save_screenshot("/private/tmp/crewbase-dark-admin.png")
    click_link "Workspace", exact: true
    assert_current_path usr_dashboards_path
    assert_selector "html[data-bs-theme='dark']"
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1000, deviceScaleFactor: 1, mobile: true)
    assert_no_selector "[data-theme-choice]"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/crewbase-dark-workspace-mobile.png")
    visit usr_settings_path
    assert_select_theme "dark"
    select "Light", from: "Appearance"
    assert_selector "html[data-bs-theme='light']"
  ensure
    page.execute_script("localStorage.removeItem('crewbase.theme')")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  private

  def assert_select_theme(value)
    assert_selector "select[aria-label='Appearance'] option[value='#{value}']:checked", visible: :all
  end
end
