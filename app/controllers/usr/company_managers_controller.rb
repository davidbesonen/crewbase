class Usr::CompanyManagersController < ApplicationController
  before_action :set_owned_company

  def show
    @entitlement = CompanyPlanEntitlement.new(@company)
    @plan = @entitlement.current_plan
    @dashboard = CompanyManagerDashboard.new(company: @company).call if @entitlement.allowed?(:staffing_analytics)
  end

  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end
end
