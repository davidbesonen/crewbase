class Usr::CompanyStaffingController < ApplicationController
  def show
    @company = current_user.owned_companies.find(params[:company_id])
    @entitlement = CompanyPlanEntitlement.new(@company)
    @project = @company.projects.find(params[:project_id]) if params[:project_id].present?
    @board = CompanyStaffingBoard.new(company: @company, from: params[:from].presence || Date.current, project: @project, query: params[:q])
    @members = @company.crew_members.includes(:profile).order(:last_name, :first_name).to_a
    response.headers["Cache-Control"] = "private, no-store"
  end
end
