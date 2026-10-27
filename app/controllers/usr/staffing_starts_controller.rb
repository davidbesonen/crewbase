class Usr::StaffingStartsController < ApplicationController
  before_action :prepare_companies

  def new
    @company = current_user.owned_companies.find(params[:company_id]) if params[:company_id].present?
    @start = StaffingStart.new(company_id: @company&.id || (@companies.first.id if @companies.one?), kind: params[:kind])
  end

  def create
    @start = StaffingStart.new(params.require(:staffing).permit(:company_id, :kind))
    if @start.valid?
      company = current_user.owned_companies.find(@start.company_id)
      if @start.kind == "multi_show"
        redirect_to new_usr_company_project_path(company)
      else
        redirect_to new_usr_company_job_path(company, staffing_kind: @start.kind, audience: "invite_only")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def prepare_companies
    @companies = current_user.owned_companies.distinct.order(:name).to_a
    redirect_to new_usr_company_path, notice: "Create your company first, then start staffing your gig." if @companies.empty?
  end
end
