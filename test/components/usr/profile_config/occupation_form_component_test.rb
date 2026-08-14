# frozen_string_literal: true

require "test_helper"

class Usr::ProfileConfig::OccupationFormComponentTest < ViewComponent::TestCase
  FakeProfile = Struct.new(:id) do
    def to_param
      id.to_s
    end
  end

  test "renders occupations alphabetically without industry pills and selected summary uses only occupation names" do
    profile = FakeProfile.new(42)
    occupations = [ occupations(:two), occupations(:one) ]
    profile_occupations = [ occupations(:two) ]

    result = render_inline(
      Usr::ProfileConfig::OccupationFormComponent.new(
        profile: profile,
        occupations: occupations,
        profile_occupations: profile_occupations,
        show_navigation: false
      )
    )

    occupation_button_texts = result.css("a[id^='occupation_button_id_']").map { |node| node.text.strip }
    selected_occupation_texts = result.css(".selected-occupation-pill").map { |node| node.text.strip }

    assert_equal [ "Audio Engineer", "Lighting Designer" ], occupation_button_texts
    assert_empty result.css(".industry-pill")
    assert_equal [ "Lighting Designer" ], selected_occupation_texts
  end
end
