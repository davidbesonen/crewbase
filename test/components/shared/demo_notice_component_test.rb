require "test_helper"

class Shared::DemoNoticeComponentTest < ViewComponent::TestCase
  test "explains the sample data and disabled integrations" do
    render_inline Shared::DemoNoticeComponent.new
    assert_text "Demo workspace"
    assert_text "fictional"
    assert_text "payments and outbound email are disabled"
  end
end
