class Usr::CrewShortlistMembershipsController < ApplicationController
  include CompanyFeatureEnforcement
  before_action :set_owned_shortlist
  before_action :require_shortlists_feature

  def create
    profile = Profile.where(profile_type: "user").find(params[:profile_id])
    @crew_shortlist.crew_shortlist_memberships.find_or_create_by!(profile:)
    redirect_back fallback_location: usr_crew_shortlist_path(@crew_shortlist), notice: "Crew member added."
  end

  def destroy
    @crew_shortlist.crew_shortlist_memberships.find_by!(profile_id: params[:profile_id]).destroy!
    redirect_back fallback_location: usr_crew_shortlist_path(@crew_shortlist), notice: "Crew member removed."
  end

  private

  def set_owned_shortlist
    @crew_shortlist = CrewShortlist
      .joins(company: :company_assignments)
      .where(company_assignments: { user_id: current_user.id, role: "owner" })
      .find(params[:crew_shortlist_id])
  end

  def require_shortlists_feature
    require_company_feature!(@crew_shortlist.company, :shortlists_pipeline)
  end
end
