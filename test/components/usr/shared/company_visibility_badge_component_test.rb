# frozen_string_literal: true

require "test_helper"

class Usr::Shared::CompanyVisibilityBadgeComponentTest < ViewComponent::TestCase
  Plan = Struct.new(:key)

  test "renders an accessible Studio badge for the enhanced visibility plan" do
    render_inline Usr::Shared::CompanyVisibilityBadgeComponent.new(plan: Plan.new("studio"))

    assert_css "span.company-visibility-badge", text: "Studio"
    assert_css ".bi-patch-check-fill[aria-hidden='true']"
    assert_css "span[aria-label='Studio company — enhanced visibility']"
  end

  test "does not render a visibility badge for lower tiers or no plan" do
    [ Plan.new("team"), Plan.new("starter"), nil ].each do |plan|
      render_inline Usr::Shared::CompanyVisibilityBadgeComponent.new(plan:)

      assert_no_css ".company-visibility-badge"
    end
  end
end
