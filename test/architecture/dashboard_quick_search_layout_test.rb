require "test_helper"

class DashboardQuickSearchLayoutTest < ActiveSupport::TestCase
  test "quick search results can extend beyond their card" do
    template = Rails.root.join("app/views/usr/dashboards/index.html.haml").read
    stylesheet = Rails.root.join("app/assets/stylesheets/application.scss").read

    assert_includes template, ".dashboard-quick-search-card"
    assert_match(/\.dashboard-quick-search-card\s*\{[^}]*overflow: visible/m, stylesheet)
  end
end
