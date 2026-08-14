require "test_helper"

class Usr::Company::CompanyPlanFormComponentTest < ViewComponent::TestCase
  test "presents plans as an increasingly capable visual hierarchy" do
    plans = %w[starter team studio].each_with_index.map do |key, index|
      Plan.new(
        id: index + 1,
        key:,
        name: key.titleize,
        monthly_price_cents: [ 1_900, 4_900, 9_900 ][index],
        annual_price_cents: [ 19_000, 49_000, 99_000 ][index],
        description: "#{key.titleize} description",
        data: {
          "seats_limit" => [ 2, 8, 25 ][index],
          "active_jobs_limit" => index.zero? ? 3 : "unlimited",
          "projects_limit" => index.zero? ? 2 : "unlimited",
          "features" => [ "Live messaging", "Staffing analytics" ]
        }
      )
    end

    render_inline(Usr::Company::CompanyPlanFormComponent.new(plans:, visible_form: "company_plan_selection"))

    assert_css ".company-plan-card--starter .company-plan-card__icon .bi-rocket-takeoff"
    assert_css ".company-plan-card--team.company-plan-card--featured .company-plan-card__icon .bi-people"
    assert_css ".company-plan-card--team .company-plan-card__badge", text: "Most Popular"
    assert_css ".company-plan-card--studio .company-plan-card__icon .bi-stars"
    assert_css ".company-plan-card__capacity", count: 9
    assert_css ".company-plan-card__feature", count: Plan::COMPANY_FEATURES.length * 3
    assert_css ".company-plan-card__feature--included .bi-check-lg.text-success", minimum: 3
    assert_css ".company-plan-card__feature--locked .bi-x-lg.text-secondary", minimum: 3
    assert_css ".company-plan-card--starter .company-plan-card__feature--locked", minimum: 1
    assert_css ".company-plan-card--studio .company-plan-card__feature--locked", count: 0
    assert_css ".company-plan-card--starter .btn-outline-primary"
    assert_css ".company-plan-card--team .btn-primary"
    assert_css ".company-plan-card--studio .btn-dark"
  end
end
