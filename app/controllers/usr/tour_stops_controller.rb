class Usr::TourStopsController < ApplicationController
  before_action :set_project

  def new
    @stops = [ {} ]
    prepare
  end

  def create
    @stops = params.fetch(:stops, ActionController::Parameters.new).values.first(50).map { |row| row.permit(:title, :starts_on, :venue_id, :venue_search, :venue_catalog_entry_id).to_h }.reject { |row| row.values.all?(&:blank?) }
    result = CreateTourStops.new(project: @project, source:, actor: current_user, stops: @stops).call
    if result.success?
      label = @project.multi_show? ? "shows" : "tour stops"
      redirect_to usr_project_path(@project), notice: "Created #{result.jobs.size} private draft #{label}. Review each before sending offers or publishing."
    else
      flash.now[:alert] = result.error
      prepare
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.where(company_id: current_user.owned_companies.select(:id)).find(params[:project_id])
  end

  def source
    return if params[:source].blank? && params[:source_job_id].blank?
    kind, id = params[:source].to_s.split(":", 2)
    return @project.company.gig_templates.find(id) if kind == "template"
    @project.company.jobs.find(id.presence || params[:source_job_id])
  end

  def prepare
    @jobs = @project.company.jobs.order(:title).to_a
    @templates = @project.company.gig_templates.order(:name).to_a
    @venues = @project.company.venues.order(:name).to_a
    @stops = [ {} ] if @stops.empty?
  end
end
