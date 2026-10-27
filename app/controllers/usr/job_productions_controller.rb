class Usr::JobProductionsController < ApplicationController
  before_action :set_job

  def show
    prepare
  end

  def update
    attributes = params.require(:job).permit(:venue_id, :briefing_notes, :production_contact_name, :production_contact_email, :production_contact_phone).to_h
    attributes["venue"] = @job.company.venues.find(attributes.delete("venue_id")) if attributes["venue_id"].present?
    attributes["venue_id"] = nil if attributes["venue_id"] == ""
    catalog_entry = VenueCatalogEntry.find(params[:venue_catalog_entry_id]) if params[:venue_catalog_entry_id].present?
    if UpdateProductionBrief.new(job: @job, actor: current_user, attributes:, catalog_entry:).call
      redirect_to usr_job_production_path(@job), notice: "Show information saved. Confirmed crew are notified of changes in KnowShow."
    else
      prepare
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_job
    @job = Job.where(company_id: current_user.owned_companies.select(:id)).find(params[:job_id])
    response.headers["Cache-Control"] = "private, no-store"
  end

  def prepare
    @workspace = ProductionWorkspace.new(job: @job)
  end
end
