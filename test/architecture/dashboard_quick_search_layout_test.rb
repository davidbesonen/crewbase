require "test_helper"

class DashboardQuickSearchLayoutTest < ActiveSupport::TestCase
  test "standalone search allows results to extend over dashboard content" do
    stylesheet = Rails.root.join("app/assets/stylesheets/_dashboard.scss").read

    assert_match(/\.dashboard-quick-search\s*\{[^}]*overflow: visible/m, stylesheet)
    assert_match(/#dashboard-quick-search-results\s*\{[^}]*z-index:/m, stylesheet)
  end
end
