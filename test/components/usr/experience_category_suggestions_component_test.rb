require "test_helper"

class Usr::ExperienceCategorySuggestionsComponentTest < ViewComponent::TestCase
  test "shows escaped evidence with an explicit non-submitting confirmation button" do
    profile = Profile.new(skills_text: "<script>alert(1)</script> audio mixing")
    render_inline Usr::ExperienceCategorySuggestionsComponent.new(suggestions: ExperienceCategorySuggestions.new(profile: profile).results)
    assert_selector "button[type='button'][data-experience-category-key='audio']", text: /Add Audio production/
    assert_text "Based on: <script>alert(1)</script> audio mixing"
    assert_no_selector "script"
    assert_no_selector "input[checked]"
  end
end
