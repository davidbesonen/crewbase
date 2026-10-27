class Usr::GigReusesController < ApplicationController
  before_action :set_company

  def new
    @source = source
  end

  def create
    @source = source
    result = ReuseGig.new(source: @source, actor: current_user, title: params[:title], starts_on: params[:starts_on]).call
    if result.success?
      redirect_to edit_usr_company_job_path(@company, result.job), notice: "Draft created. Review dates, location and requirements before publishing. No crew bookings were copied."
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_company = @company = current_user.owned_companies.find(params[:company_id])

  def source
    params[:template_id].present? ? @company.gig_templates.find(params[:template_id]) : @company.jobs.find(params[:source_job_id])
  end
end
