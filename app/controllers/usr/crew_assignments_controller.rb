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
    if @assignment.job_offer
      redirect_to usr_job_offer_path(@assignment.job_offer), notice: "Cancel this booking with a reason to notify the worker."
    else
      @assignment.destroy!
      redirect_to usr_job_crew_path(job), notice: "Crew member removed."
    end
  end

  private

  def save_assignment(position:, assignment: nil)
    profile = JobCrewCandidateQuery.new(job: position.job, user: current_user).profiles.find(assignment_params.fetch(:profile_id))
    redirect_to new_usr_job_offer_path(crew_position_id: position.id, profile_id: profile.id),
      notice: assignment ? "Send the replacement an offer. Cancel the existing booking before the replacement accepts." : "Confirm the terms before sending this person an offer."
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
