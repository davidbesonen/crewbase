require "application_system_test_case"

class KnowshowBrandingTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "logo options and the new site work on desktop and mobile with readable artwork" do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    page.driver.browser.manage.window.resize_to(1440, 1600)
    visit brand_directions_path
    assert_selector "[data-brand-direction]", count: 4
    assert_selector ".brand-direction__stage img", count: 4
    assert page.evaluate_script("Array.from(document.querySelectorAll('.brand-wordmark img')).every(image => image.complete && image.naturalWidth > 0)")
    page.save_screenshot("/private/tmp/knowshow-logo-options.png")

    within("[data-brand-direction='afterhours']") { click_link "Preview site" }
    page.driver.browser.manage.window.resize_to(1440, 1000)
    assert_selector "main[data-brand-concept='afterhours']"
    assert_selector "h1", text: "Know your crew."
    assert_selector ".marketing-nav img[src*='knowshow-afterhours-on-dark']"
    page.driver.browser.manage.window.resize_to(1890, 1000)
    page.evaluate_async_script("document.fonts.ready.then(() => arguments[0](true))")
    assert_equal 1, page.evaluate_script(<<~JS)
      (() => {
        const heading = document.querySelector('.marketing-hero h1');
        const text = Array.from(heading.childNodes).find(node => node.nodeType === Node.TEXT_NODE && node.textContent.trim());
        const range = document.createRange();
        range.selectNodeContents(text);
        return Array.from(range.getClientRects()).filter(rect => rect.width > 0).length;
      })()
    JS
    page.driver.browser.manage.window.resize_to(1440, 1000)
    select "Light", from: "Appearance"
    assert_selector "html[data-bs-theme='light']"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/knowshow-home-desktop.png")

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    assert_selector ".marketing-nav .brand-wordmark"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/knowshow-home-mobile.png")
    select "Dark", from: "Appearance"
    assert_selector "html[data-bs-theme='dark']"
    visit new_user_session_path
    assert_selector "[aria-label='KnowShow']"
    assert_title "KnowShow", exact: false
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
    Warden.test_reset!
  end
end
