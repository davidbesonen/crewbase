require "test_helper"

class MarketingStylesTest < ActiveSupport::TestCase
  setup do
    @stylesheet = File.read(Rails.root.join("app/assets/stylesheets/_marketing.scss"))
  end

  test "navigation content spans the viewport with a consistent edge gutter" do
    nav_inner_rule = @stylesheet.match(/\.marketing-nav__inner\s*\{(?<body>.*?)\}/m)

    assert nav_inner_rule, "Expected a marketing navigation inner rule"
    assert_match(/width:\s*calc\(100%\s*-\s*[^)]+\)/, nav_inner_rule[:body])
    assert_match(/max-width:\s*none/, nav_inner_rule[:body])
  end

  test "full-width sections own their background while readable content stays contained" do
    %w[marketing-hero marketing-trust-strip marketing-platform marketing-cta marketing-footer].each do |section|
      assert_match(/\.#{section}\s*\{/, @stylesheet)
    end

    assert_match(/\.marketing-container\s*\{.*?max-width:\s*1180px/m, @stylesheet)
  end

  test "homepage does not clip content beyond the viewport" do
    homepage_rule = @stylesheet.match(/\.marketing-home\s*\{(?<body>.*?)\}/m)

    assert homepage_rule, "Expected a marketing homepage rule"
    refute_match(/overflow:\s*hidden/, homepage_rule[:body])
  end

  test "bottom call to action headline is explicitly centered" do
    cta_rule = @stylesheet.match(/\.marketing-cta\s*\{(?<body>.*?)\}/m)
    cta_inner_rule = @stylesheet.match(/\.marketing-cta__inner\s*\{(?<body>.*?)\}/m)
    cta_heading_rule = @stylesheet.scan(/\.marketing-cta h2\s*\{(?<body>.*?)\}/m).last

    assert cta_rule, "Expected a bottom call to action section"
    assert cta_inner_rule, "Expected a bottom call to action container"
    assert cta_heading_rule, "Expected a bottom call to action heading rule"
    assert_match(/display:\s*grid/, cta_rule[:body])
    assert_match(/place-items:\s*center/, cta_rule[:body])
    assert_match(/width:\s*calc\(100%\s*-\s*2rem\)/, cta_inner_rule[:body])
    assert_match(/margin-inline:\s*auto/, cta_inner_rule[:body])
    assert_match(/text-align:\s*center/, cta_inner_rule[:body])
    assert_match(/width:\s*100%/, cta_heading_rule.first)
    assert_match(/margin-inline:\s*auto/, cta_heading_rule.first)
    assert_match(/text-align:\s*center/, cta_heading_rule.first)
  end
end
