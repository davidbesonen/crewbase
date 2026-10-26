require "test_helper"

class Usr::Dashboard::QuickSearchComponentTest < ViewComponent::TestCase
  test "renders an accessible standalone live search with keyboard controls" do
    render_inline(Usr::Dashboard::QuickSearchComponent.new(search_path: "/usr/dashboards/quick_search"))

    assert_selector "[role='search'][aria-label='Quick search']" do
      assert_selector ".card", count: 0
      assert_selector "[data-quick-search-url-value='/usr/dashboards/quick_search']"
      assert_selector "input[role='combobox'][aria-autocomplete='list'][aria-expanded='false']"
      assert_selector "input[aria-controls='dashboard-quick-search-results'][data-action*='keydown->quick-search#navigate']"
      assert_selector "#dashboard-quick-search-results[role='listbox'][data-quick-search-target='results']", visible: :all
      assert_selector "[role='status'][aria-live='polite']", visible: :all
    end
  end
end
