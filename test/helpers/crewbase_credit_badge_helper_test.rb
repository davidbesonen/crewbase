require "test_helper"

class CrewbaseCreditBadgeHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "renders blue and neutral verified-credit variants" do
    blue = crewbase_credit_badge(variant: :blue)
    neutral = crewbase_credit_badge(variant: :neutral, compact: true)

    assert_includes blue, "crewbase-credit-badge-blue"
    assert_includes blue, "crewbase-credit-badge-blue.svg"
    assert_includes blue, "Crewbase Credit"
    assert_includes neutral, "crewbase-credit-badge-neutral"
    assert_includes neutral, "crewbase-credit-badge-neutral.svg"
    assert_includes neutral, 'aria-label="Verified Crewbase Credit"'
    refute_includes neutral, ">Crewbase Credit<"
  end

  test "badge artwork centers a rounded checkmark inside concentric circles" do
    %w[blue neutral].each do |variant|
      document = Nokogiri::XML(
        Rails.root.join("app/assets/images/crewbase-credit-badge-#{variant}.svg").read
      )

      assert_equal 2, document.xpath("//*[local-name()='circle'][@cx='32'][@cy='32']").size
      assert_equal 1, document.xpath("//*[local-name()='path'][@data-badge-check][@stroke-linecap='round'][@stroke-linejoin='round']").size
    end
  end
end
