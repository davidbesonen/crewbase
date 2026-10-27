class Usr::CrewHoldsController < ApplicationController
  before_action :set_job

  def create
    member = @job.company.crew_members.find(params[:crew_member_id])
    @job.crew_holds.find_or_create_by!(crew_member: member, crew_position: @position)
    redirect_to board_path, notice: "Tentative crew added. This is not a confirmed booking. Send an offer once their profile is claimed."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to board_path, alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    @job.crew_holds.find(params[:id]).destroy!
    redirect_to board_path, notice: "Tentative crew removed."
  end

  private

  def set_job
    if params[:crew_position_id].present?
      @position = CrewPosition.joins(:job).where(jobs: { company_id: current_user.owned_companies.select(:id) }).find(params[:crew_position_id])
      @job = @position.job
    else
      @job = Job.where(company_id: current_user.owned_companies.select(:id), posting_type: :single_role).find(params[:job_id])
    end
  end

  def board_path
    usr_company_staffing_path(@job.company, project_id: @job.project_id, from: @job.starts_at&.to_date || Date.current)
  end
end
