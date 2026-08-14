class Usr::CrewAssignmentsController < ApplicationController
  before_action :set_owned_position, only: :create
  before_action :set_owned_assignment, only: [ :update, :destroy ]

  def create
    save_assignment(position: @position)
  end

  def update
    save_assignment(position: @assignment.crew_position, assignment: @assignment)
  end

  def destroy
    job = @assignment.crew_position.job
    @assignment.destroy
    redirect_to usr_job_crew_path(job), notice: "Crew member removed."
  end

  private

  def save_assignment(position:, assignment: nil)
    profile = Profile.find(assignment_params.fetch(:profile_id))
    manager = CrewAssignmentManager.new(position:, profile:, assignment:, user: current_user)

    if manager.call
      redirect_to usr_job_crew_path(position.job), notice: assignment ? "Crew member reassigned." : "Crew member assigned."
    else
      redirect_to usr_job_crew_path(position.job), alert: "Crew member could not be assigned."
    end
  end

  def set_owned_position
    @position = CrewPosition.joins(job: { company: :company_assignments })
      .find_by!(
        id: params[:crew_position_id],
        jobs: { posting_type: Job.posting_types[:multi_position] },
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def set_owned_assignment
    @assignment = CrewAssignment.joins(crew_position: { job: { company: :company_assignments } })
      .find_by!(
        id: params[:id],
        jobs: { posting_type: Job.posting_types[:multi_position] },
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def assignment_params
    params.require(:crew_assignment).permit(:profile_id)
  end
end
