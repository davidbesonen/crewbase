class Usr::JobPlacementsController < ApplicationController
  before_action :set_company

  def new
    @values = {}
    prepare_choices
  end

  def create
    @values = params.require(:placement).permit(:kind, :project_id, :job_id).to_h
    destination = case @values["kind"]
    when "standalone"
      new_usr_company_job_path(@company)
    when "project"
      raise ArgumentError, "Choose a project, or start a new tour / festival Project below." if @values["project_id"].blank?
      project = @company.projects.active.find(@values["project_id"])
      new_usr_company_job_path(@company, project_id: project.id)
    when "gig"
      raise ArgumentError, "Choose the gig that needs another role." if @values["job_id"].blank?
      gig = @company.jobs.multi_position.where.not(status: %i[archived completed closed]).find(@values["job_id"])
      usr_job_crew_path(gig, anchor: "add-crew-position")
    else
      raise ArgumentError, "Choose where this job belongs."
    end
    redirect_to destination
  rescue ArgumentError => error
    flash.now[:alert] = error.message
    prepare_choices
    render :new, status: :unprocessable_entity
  end

  private

  def set_company = @company = current_user.owned_companies.find(params[:company_id])

  def prepare_choices
    @projects = @company.projects.active.order(:name).to_a
    @gigs = @company.jobs.multi_position.where.not(status: %i[archived completed closed]).order(:title).to_a
  end
end
