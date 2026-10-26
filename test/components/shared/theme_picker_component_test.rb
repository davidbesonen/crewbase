require "test_helper"

class Shared::ThemePickerComponentTest < ViewComponent::TestCase
  test "appearance control has an accessible name and explicit system preference" do
    render_inline Shared::ThemePickerComponent.new
    assert_selector "select[aria-label='Appearance'][data-theme-choice]"
    assert_selector "option[value='system']", text: "System"
    assert_selector "option[value='light']", text: "Light"
    assert_selector "option[value='dark']", text: "Dark"
    assert_selector "i[aria-hidden='true']", visible: :all
  end
end
