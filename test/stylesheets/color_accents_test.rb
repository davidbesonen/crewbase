require "test_helper"

class ColorAccentsTest < ActiveSupport::TestCase
  setup do
    path = Rails.root.join("app/assets/stylesheets/_color_accents.scss")
    @stylesheet = path.exist? ? File.read(path) : ""
    @application_stylesheet = File.read(Rails.root.join("app/assets/stylesheets/application.scss"))
  end

  test "loads the shared accent system" do
    assert_includes @application_stylesheet, '@import "color_accents";'
  end

  test "defines restrained semantic color tokens" do
    %w[navy cyan sky].each do |color|
      assert_includes @stylesheet, "--app-accent-#{color}"
      assert_includes @stylesheet, "--app-surface-#{color}"
    end

    %w[amber coral green lavender].each do |color|
      refute_includes @stylesheet, "--app-accent-#{color}"
      refute_includes @stylesheet, "--app-surface-#{color}"
    end
  end

  test "provides reusable surface and accent treatments" do
    %w[app-hero card-accent icon-orb empty-state].each do |component|
      assert_includes @stylesheet, ".#{component}"
    end

    %w[navy cyan sky].each do |color|
      assert_includes @stylesheet, ".app-hero-#{color}"
      assert_includes @stylesheet, ".card-accent-#{color}"
      assert_includes @stylesheet, ".icon-orb-#{color}"
      assert_includes @stylesheet, ".empty-state-#{color}"
    end
  end

  test "provides readable semantic status badges" do
    %w[open draft completed available unknown unavailable warning].each do |status|
      assert_includes @stylesheet, ".status-#{status}"
    end

    assert_includes @stylesheet, ".status-badge"
  end

  test "keeps larger color surfaces pale" do
    assert_match(/--app-surface-navy:\s*#[Ff]0[Ff]5[Ff]8/, @stylesheet)
    assert_match(/--app-surface-cyan:\s*#[Ee][Ff][Ff]9[Ff][Bb]/, @stylesheet)
    assert_match(/--app-surface-sky:\s*#[Ff]2[Ff]8[Ff][Cc]/, @stylesheet)
  end

  test "card accents use a slim side rail on a clean solid surface" do
    card_accent_rule = @stylesheet.match(/\.card-accent\s*\{(?<body>.*?)\}/m)
    rail_rule = @stylesheet.match(/\.card-accent::before\s*\{(?<body>.*?)\}/m)

    assert card_accent_rule, "Expected a shared card accent rule"
    assert rail_rule, "Expected a shared card accent rail"
    assert_match(/background-color/, card_accent_rule[:body])
    assert_match(/width:\s*3px/, rail_rule[:body])
    assert_match(/background-color:\s*var\(--app-accent-color\)/, rail_rule[:body])
    refute_match(/gradient/, card_accent_rule[:body])
    refute_match(/border-(top|right|bottom|left)/, card_accent_rule[:body])
  end

  test "hero cards use a clean white surface without blue fills or gradients" do
    hero_rule = @stylesheet.match(/\.app-hero\s*\{(?<body>.*?)\}/m)

    assert hero_rule, "Expected a shared hero accent rule"
    assert_match(/background-color:\s*var\(--bs-card-bg\)/, hero_rule[:body])
    refute_match(/gradient/, hero_rule[:body])
  end

  test "application background is a consistent solid color rather than a gradient behind cards" do
    assert_includes @application_stylesheet, "background-color: var(--bs-tertiary-bg);"
    refute_includes @application_stylesheet, "linear-gradient(180deg, #f8f8f8 0%, #f0f0f0 100%)"
  end
end
