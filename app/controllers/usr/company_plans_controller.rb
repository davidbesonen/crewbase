class Usr::CompanyPlansController < ApplicationController
  before_action :set_owned_company

  def show
    prepare_plan_management
  end

  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end

  def prepare_plan_management
    @entitlement = CompanyPlanEntitlement.new(@company)
    @current_plan = @entitlement.current_plan
    current_rank = Plan::TIER_RANKS.fetch(@current_plan&.key, -1)
    @upgrade_plans = Plan.active.select do |plan|
      Plan::TIER_RANKS.fetch(plan.key, -1) > current_rank
    end
  end
end
