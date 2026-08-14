require "test_helper"

class BootstrapFormBuilderTest < ActionView::TestCase
  Option = Data.define(:id, :name)

  test "collection select remains HTML when its automatic label is disabled" do
    builder = BootstrapFormBuilder.new(:crew_assignment, CrewAssignment.new, self, {})

    html = builder.collection_select(
      :profile_id,
      [ Option.new(id: 7, name: "Landon Mason") ],
      :id,
      :name,
      { prompt: "Select a crew member", label: false },
      class: "form-select"
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_predicate html, :html_safe?
    assert_equal 1, fragment.css("select.form-select").count
    assert_equal [ "form-select" ], fragment.at_css("select")["class"].split
    assert_equal [ "Select a crew member", "Landon Mason" ], fragment.css("option").map(&:text)
    assert_not_includes fragment.text, "<select"
  end
end
