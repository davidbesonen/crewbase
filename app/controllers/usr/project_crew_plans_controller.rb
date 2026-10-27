class Usr::ProjectCrewPlansController < ApplicationController
  before_action :set_project

  def new
    @values = { "show_coverage" => "all_shows" }
    prepare_form
  end

  def create
    @values = params.require(:crew_plan).permit(:title, :crew_member_id, :show_coverage, project_show_ids: []).to_h
    PlanProjectCrew.new(project: @project, actor: current_user, attributes: @values).call
    redirect_to usr_project_path(@project, view: "crew"), notice: "Crew need added. Roster selections are tentative until an offer is accepted."
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    prepare_form
    render :new, status: :unprocessable_entity
  end

  private

  def set_project
    @project = Project.active.where(company_id: current_user.owned_companies.select(:id)).find(params[:project_id])
  end

  def prepare_form
    @shows = @project.project_shows.chronological.to_a
    @members = @project.company.crew_members.order(:first_name, :last_name).to_a
  end
end
