class CrewClaimsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  before_action :set_member

  def show
    @marketing_page = true
    @page_title = "Complete your crew profile | KnowShow"
    session[:return_to_after_auth] = crew_claim_path(params[:token]) unless current_user
    @matching_account = !current_user || @member.invitation_email_matches?(current_user)
  end

  def switch_account
    sign_out current_user
    session[:return_to_after_auth] = crew_claim_path(params[:token])
    redirect_to new_user_session_path, status: :see_other, notice: "Sign in with your invited email address to continue."
  end

  def create
    result = ClaimCrewMember.new(member: @member, user: current_user, token: params[:token]).call
    if result.success?
      redirect_to edit_usr_profile_path(@member.reload.profile, source: "crew_roster"), notice: "Your imported details are ready. Review your profile and finish setting it up."
    else
      redirect_to crew_claim_path(params[:token]), alert: result.error
    end
  end

  private

  def set_member
    @member = CrewMember.find_by_token_for!(:claim, params[:token])
    raise ActiveRecord::RecordNotFound unless @member.invitation_active? && !@member.company.restricted_at?
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    @marketing_page = true
    render :unavailable, status: :not_found
  end
end
