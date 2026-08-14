# frozen_string_literal: true

require "test_helper"

class ProfileCreditsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "credits heading removes global title spacing so the icon centers on the text" do
    stylesheet = File.read(Rails.root.join("app/assets/stylesheets/application.scss"))
    heading_rule = stylesheet.match(/\.profile-credits-heading\s*\{(?<body>.*?)^\}/m)

    assert heading_rule
    assert_match(/align-items:\s*center/, heading_rule[:body])
    assert_match(/\.card-section-title\s*\{[^}]*margin:\s*0\s*!important/m, heading_rule[:body])
    assert_match(/\.card-section-title\s*\{[^}]*padding:\s*0/m, heading_rule[:body])
  end
end
