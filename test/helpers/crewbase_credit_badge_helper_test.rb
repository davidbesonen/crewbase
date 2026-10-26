require "test_helper"

class KnowShowCreditBadgeHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "renders blue and neutral verified-credit variants" do
    blue = knowshow_credit_badge(variant: :blue)
    neutral = knowshow_credit_badge(variant: :neutral, compact: true)

    assert_includes blue, "knowshow-credit-badge-blue"
    assert_includes blue, "knowshow-credit-badge-blue.svg"
    assert_includes blue, "KnowShow Credit"
    assert_includes neutral, "knowshow-credit-badge-neutral"
    assert_includes neutral, "knowshow-credit-badge-neutral.svg"
    assert_includes neutral, 'aria-label="Verified KnowShow Credit"'
    refute_includes neutral, ">KnowShow Credit<"
  end

  test "badge artwork centers a rounded checkmark inside concentric circles" do
    %w[blue neutral].each do |variant|
      document = Nokogiri::XML(
        Rails.root.join("app/assets/images/knowshow-credit-badge-#{variant}.svg").read
      )

      assert_equal 2, document.xpath("//*[local-name()='circle'][@cx='32'][@cy='32']").size
      assert_equal 1, document.xpath("//*[local-name()='path'][@data-badge-check][@stroke-linecap='round'][@stroke-linejoin='round']").size
    end
  end
end
