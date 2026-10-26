require "application_system_test_case"

class MarketingConcertTest < ApplicationSystemTestCase
  self.fixture_table_names = []

  test "concert motion can be paused and follows reduced motion preferences on desktop and mobile" do
    page.driver.browser.manage.window.resize_to(1440, 1100)
    set_reduced_motion(false)
    visit welcome_path
    assert_selector ".marketing-nav img[src*='knowshow-drive-on-dark']"

    assert_selector ".concert-scene img[alt*='saxophonist']"
    assert page.evaluate_script("document.querySelector('.concert-scene img').complete && document.querySelector('.concert-scene img').naturalWidth > 0")
    assert_selector ".concert-scene[data-motion='playing']"
    assert_equal "running", stage_animation_state
    click_button "Pause animation"
    assert_button "Play animation"
    assert_equal "paused", stage_animation_state
    click_button "Play animation"
    assert_button "Pause animation"
    assert_equal "running", stage_animation_state
    page.save_screenshot("/private/tmp/knowshow-concert-desktop.png")

    set_reduced_motion(true)
    assert_no_button "Pause animation"
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.concert-scene__stage')).animationName")
    set_reduced_motion(false)
    assert_button "Pause animation"
    assert_equal "running", stage_animation_state

    page.execute_script("document.querySelector('#pricing').scrollIntoView({block: 'center', behavior: 'instant'})")
    assert_selector ".concert-scene[data-motion='paused']", visible: :all
    assert_equal "paused", stage_animation_state

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    page.execute_script("document.querySelector('.concert-scene').scrollIntoView({block: 'center', behavior: 'instant'})")
    assert_selector ".concert-scene[data-motion='playing']"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-concert-mobile.png")

    set_reduced_motion(true)
    page.refresh
    assert_selector ".concert-scene[data-motion='paused']"
    assert_no_button "Pause animation"
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.concert-scene__stage')).animationName")
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  private

  def stage_animation_state
    page.evaluate_script("getComputedStyle(document.querySelector('.concert-scene__stage')).animationPlayState")
  end

  def set_reduced_motion(reduced)
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: reduced ? "reduce" : "no-preference" } ])
  end
end
