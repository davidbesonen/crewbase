class Usr::CrewShortlistsController < ApplicationController
  include CompanyFeatureEnforcement
  before_action :set_owned_company, only: [ :index, :create ]
  before_action :set_owned_shortlist, only: [ :show, :destroy ]
  before_action :require_shortlists_feature

  def index
    @crew_shortlists = @company.crew_shortlists.includes(profiles: :user).order(:name)
    @crew_shortlist = @company.crew_shortlists.new
  end

  def show
  end

  def create
    shortlist = @company.crew_shortlists.new(crew_shortlist_params.merge(created_by: current_user))
    if shortlist.save
      redirect_to usr_crew_shortlist_path(shortlist), notice: "Crew shortlist created."
    else
      @crew_shortlists = @company.crew_shortlists.includes(profiles: :user).order(:name)
      @crew_shortlist = shortlist
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    company = @crew_shortlist.company
    @crew_shortlist.destroy!
    redirect_to usr_company_crew_shortlists_path(company), notice: "Crew shortlist deleted."
  end

  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end

  def set_owned_shortlist
    @crew_shortlist = CrewShortlist
      .includes(profiles: :user)
      .joins(company: :company_assignments)
      .where(company_assignments: { user_id: current_user.id, role: "owner" })
      .find(params[:id])
  end

  def crew_shortlist_params
    params.require(:crew_shortlist).permit(:name)
  end

  def require_shortlists_feature
    require_company_feature!(@company || @crew_shortlist.company, :shortlists_pipeline)
  end
end
