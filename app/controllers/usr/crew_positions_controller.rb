class Usr::CrewPositionsController < ApplicationController
  before_action :set_owned_job, only: :create
  before_action :set_owned_position, only: :destroy

  def create
    position = @job.crew_positions.new(position_params)
    if position.save
      redirect_to usr_job_crew_path(@job), notice: "Crew position added."
    else
      redirect_to usr_job_crew_path(@job), alert: position.errors.full_messages.to_sentence
    end
  end

  def destroy
    job = @position.job
    @position.destroy
    redirect_to usr_job_crew_path(job), notice: "Crew position removed."
  end

  private

  def set_owned_job
    @job = owned_jobs.find(params[:job_id])
  end

  def set_owned_position
    @position = CrewPosition.joins(job: { company: :company_assignments })
      .find_by!(
        id: params[:id],
        jobs: { posting_type: Job.posting_types[:multi_position] },
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def owned_jobs
    Job.joins(company: :company_assignments)
      .where(
        posting_type: :multi_position,
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def position_params
    params.require(:crew_position).permit(:title, :headcount, :description, :pay_min, :pay_max, :pay_period)
  end
end
