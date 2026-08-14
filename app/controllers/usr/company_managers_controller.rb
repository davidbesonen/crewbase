class Usr::CompanyManagersController < ApplicationController
  include CompanyFeatureEnforcement
  before_action :set_owned_company
  before_action :require_analytics_feature

  def show
    @plan = @company.company_plans.includes(:plan).order(created_at: :desc).first&.plan
    @dashboard = CompanyManagerDashboard.new(company: @company).call
  end


  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end

  def require_analytics_feature
    require_company_feature!(@company, :staffing_analytics)
  end
end
