# frozen_string_literal: true

require "test_helper"

class CardTitlesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "card titles share slightly larger type and spacing across the app" do
    stylesheet = File.read(Rails.root.join("app/assets/stylesheets/application.scss"))
    profile_show = File.read(Rails.root.join("app/views/usr/profiles/show.html.haml"))

    assert_includes stylesheet, ".card-title,\n.card-section-title"
    assert_includes stylesheet, "font-size: 1.3rem"
    assert_includes stylesheet, "padding: 0.125rem"

    assert_includes profile_show, "%h5.card-section-title.fw-bold About"
    assert_includes profile_show, "%h5.card-section-title.fw-bold Core Skills"
    assert_includes profile_show, "%h5.card-section-title.fw-bold Recent Feedback"
  end
end
