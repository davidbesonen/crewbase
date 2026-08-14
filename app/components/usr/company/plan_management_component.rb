class Usr::Company::PlanManagementComponent < ApplicationComponent
  def initialize(company:, current_plan:, upgrade_plans:)
    @company = company
    @current_plan = current_plan
    @upgrade_plans = upgrade_plans
  end

  private

  attr_reader :company, :current_plan, :upgrade_plans

  def included_features(plan)
    plan.feature_matrix.select { |feature| feature.fetch(:included) }
  end
end
