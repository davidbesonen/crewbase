# frozen_string_literal: true

require "test_helper"

class MarketingMotionTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "marketing motion progressively enhances scrolling and respects reduced motion" do
    stylesheet = File.read(Rails.root.join("app/assets/stylesheets/_marketing.scss"))
    controller = File.read(Rails.root.join("app/javascript/controllers/marketing_motion_controller.js"))

    assert_includes stylesheet, ".marketing-home.is-motion-ready"
    assert_includes stylesheet, ".is-revealed"
    assert_includes stylesheet, "--marketing-scroll-progress"
    assert_match(/@media \(prefers-reduced-motion: reduce\)/, stylesheet)

    assert_includes controller, "IntersectionObserver"
    assert_includes controller, 'matchMedia("(prefers-reduced-motion: reduce)")'
    assert_includes controller, "requestAnimationFrame"
    assert_includes controller, "--marketing-parallax-offset"
    assert_includes controller, "--marketing-scroll-progress"
    assert_includes controller, 'classList.remove("is-revealed")'
    refute_includes controller, "this.observer.unobserve(entry.target)"
  end
end
