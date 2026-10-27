class Usr::GigTemplatesController < ApplicationController
  before_action :set_company

  def index
    @templates = @company.gig_templates.order(:name).to_a
    @entitlement = CompanyPlanEntitlement.new(@company)
  end

  def create
    job = @company.jobs.find(params[:source_job_id])
    GigTemplate.capture!(job:, name: params[:name].to_s.strip, user: current_user)
    redirect_to usr_company_gig_templates_path(@company), notice: "Gig setup saved. Templates do not contain applicants, offers or bookings."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to usr_job_production_path(job), alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    @company.gig_templates.find(params[:id]).destroy!
    redirect_to usr_company_gig_templates_path(@company), notice: "Template removed. Existing gigs are unchanged."
  end

  private

  def set_company = @company = current_user.owned_companies.find(params[:company_id])
end
