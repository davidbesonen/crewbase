class Usr::ProductionDaysController < ApplicationController
  before_action :set_job

  def create
    day = @job.production_days.new(day_params)
    save(day)
  end

  def update
    day = @job.production_days.find(params[:id])
    day.assign_attributes(day_params)
    save(day)
  end

  def destroy
    @job.transaction do
      @job.production_days.find(params[:id]).destroy!
      @job.touch
      NotifyProductionCrew.new(job: @job, actor: current_user).call
    end
    redirect_to usr_job_production_path(@job), notice: "Schedule item removed. Accepted booking times are unchanged."
  end

  private

  def set_job
    @job = Job.where(company_id: current_user.owned_companies.select(:id)).find(params[:job_id])
    response.headers["Cache-Control"] = "private, no-store"
  end
  def day_params = params.require(:production_day).permit(:date, :day_type, :label, :starts_at, :ends_at, :notes)

  def save(day)
    day.transaction do
      day.save!
      changed = day.saved_changes.except("updated_at").any?
      @job.touch
      NotifyProductionCrew.new(job: @job, actor: current_user).call if changed
    end
    redirect_to usr_job_production_path(@job), notice: "Schedule saved. Accepted booking times are unchanged."
  rescue ActiveRecord::RecordInvalid
    @workspace = ProductionWorkspace.new(job: @job, schedule_item: day)
    render "usr/job_productions/show", status: :unprocessable_entity
  end
end
