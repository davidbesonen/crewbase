require "test_helper"

class ButtonSystemTest < ActiveSupport::TestCase
  setup do
    @stylesheet = File.read(Rails.root.join("app/assets/stylesheets/colors.scss"))
  end

  test "base button styling preserves Bootstrap size variants" do
    base_rule = @stylesheet.match(/\.btn\s*\{(?<body>.*?)^\}/m)

    assert base_rule, "Expected a shared .btn rule"
    refute_match(/^\s*(padding|font-size):/, base_rule[:body])
    assert_includes @stylesheet, ".btn-sm"
    assert_includes @stylesheet, ".btn-lg"
  end

  test "button roles include a neutral quiet action and accessible interaction states" do
    assert_includes @stylesheet, "&-quiet"
    assert_includes @stylesheet, "&:focus-visible"
    assert_includes @stylesheet, "&:disabled"
    assert_includes @stylesheet, ".btn-icon"
    assert_includes @stylesheet, ".btn-group-responsive"
  end

  test "secondary remains an accent while quiet actions use neutral colors" do
    quiet_rule = @stylesheet.match(/&-quiet\s*\{(?<body>.*?)^\s{2}\}/m)

    assert quiet_rule, "Expected a btn-quiet role"
    assert_match(/\$button-neutral/, quiet_rule[:body])
    refute_match(/\$secondary/, quiet_rule[:body])
  end
end
