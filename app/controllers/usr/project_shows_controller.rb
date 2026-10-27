class Usr::ProjectShowsController < ApplicationController
  before_action :set_project
  before_action :set_show, only: [ :edit, :update, :destroy ]

  def new
    @rows = [ {} ]
  end

  def create
    @rows = params.fetch(:shows, ActionController::Parameters.new).values.first(51)
      .map { |row| row.permit(*show_fields).to_h }.reject { |row| row.except("show_count", "show_count_choice").values.all?(&:blank?) }
    save_shows
  end

  def edit
    @rows = [ @show.attributes.slice(*show_fields.map(&:to_s)) ]
  end

  def update
    @rows = [ params.require(:show).permit(*show_fields).to_h ]
    save_shows
  end

  def destroy
    if @show.destroy
      redirect_to usr_project_path(@project), notice: "Show removed."
    else
      redirect_to usr_project_path(@project), alert: "This show has staffing attached. Change the roles' show coverage before removing it."
    end
  end

  private

  def set_project
    @project = Project.active.where(company_id: current_user.owned_companies.select(:id)).find(params[:project_id])
  end

  def set_show = @show = @project.project_shows.find(params[:id])
  def show_fields = %i[name city state country venue_name starts_on ends_on show_time show_count show_count_choice]

  def save_shows
    result = SaveProjectShows.new(project: @project, rows: @rows, show: @show).call
    if result.success?
      redirect_to usr_project_path(@project), notice: "Show schedule saved. Linked posting dates and cities are updated. Existing offers keep their agreed terms."
    else
      flash.now[:alert] = result.error
      render @show ? :edit : :new, status: :unprocessable_entity
    end
  end
end
