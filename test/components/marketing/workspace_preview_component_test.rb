require "test_helper"

class Marketing::WorkspacePreviewComponentTest < ViewComponent::TestCase
  test "illustrates recommendations without claiming real availability or match percentages" do
    render_inline Marketing::WorkspacePreviewComponent.new

    assert_selector ".marketing-crew-row", count: 3
    assert_selector ".marketing-crew-reason", count: 3
    assert_text "Illustrative workspace · not live availability"
    assert_no_text(/\d+%/)
  end
end
