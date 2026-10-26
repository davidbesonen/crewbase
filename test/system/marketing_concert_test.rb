require "application_system_test_case"

class MarketingConcertTest < ApplicationSystemTestCase
  self.fixture_table_names = []

  test "company-first marketing keeps a clear crew path and a still concert illustration on desktop and mobile" do
    page.driver.browser.manage.window.resize_to(1440, 1100)
    set_reduced_motion(false)
    visit welcome_path

    assert_selector ".marketing-nav img[src*='knowshow-drive-on-dark']"
    assert_selector "h1", text: "Staff your gigs."
    assert_link "Start staffing", href: new_user_registration_path
    assert_selector ".concert-scene img[alt*='saxophonist']"
    assert page.evaluate_script("document.querySelector('.concert-scene img').complete && document.querySelector('.concert-scene img').naturalWidth > 0")
    assert_no_button "Pause animation", visible: :all
    assert_no_button "Play animation", visible: :all
    assert_equal 0, scene_animation_count
    page.save_screenshot("/private/tmp/knowshow-company-marketing-desktop.png")

    within(".marketing-hero") { click_link "Looking for gigs?" }
    assert_selector "#for-crew h2", text: "Looking for your next gig?"
    within("#for-crew") { click_link "Create your free profile" }
    assert_current_path new_user_registration_path
    assert_selector "form input[type='email']"

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    visit welcome_path
    assert_selector "h1", text: "Staff your gigs."
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.execute_script("document.querySelector('.concert-scene').scrollIntoView({block: 'center', behavior: 'instant'})")
    assert_equal 0, scene_animation_count
    assert_no_selector ".concert-scene button", visible: :all
    page.save_screenshot("/private/tmp/knowshow-company-marketing-mobile.png")

    set_reduced_motion(true)
    page.refresh
    assert_selector ".concert-scene img"
    assert_equal 0, scene_animation_count
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  private

  def scene_animation_count
    page.evaluate_script("document.querySelector('.concert-scene').getAnimations({subtree: true}).length")
  end

  def set_reduced_motion(reduced)
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: reduced ? "reduce" : "no-preference" } ])
  end
end
