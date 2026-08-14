require "test_helper"

class ExperienceTest < ActiveSupport::TestCase
  test "selected company sets company name from company record" do
    experience = Experience.new(
      profile: profiles(:one),
      title: "Audio Engineer",
      company_name: "Typed Name",
      company: companies(:one)
    )

    experience.valid?

    assert_equal companies(:one).name, experience.company_name
  end

  test "display timeframe includes months when present" do
    experience = Experience.new(
      profile: profiles(:one),
      title: "Audio Engineer",
      company_name: "Festival Production Group",
      start_month: "January",
      start_year: "2024",
      end_month: "March",
      end_year: "2025"
    )

    assert_equal "January 2024 - March 2025", experience.display_timeframe
  end
end
