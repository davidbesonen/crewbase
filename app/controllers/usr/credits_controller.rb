class Usr::CreditsController < ApplicationController
  before_action :set_profile
  before_action :set_credit, only: [ :update ]

  def new
    head :not_found
  end

  def create
    head :not_found
  end

  def edit
    head :not_found
  end

  def update
    return head :not_found unless credit_params.key?(:visible) && credit_params.keys.one?

    @credit.update!(visible: credit_params[:visible])
    redirect_to profile_credits_path, notice: "Credit visibility updated."
  end

  def destroy
    head :not_found
  end

  private

  def set_profile
    @profile = current_user.profiles.find(params[:profile_id])
  end

  def set_credit
    @credit = @profile.credits.find(params[:id])
  end

  def credit_params
    params.require(:credit).permit(
      :visible
    )
  end

  def profile_credits_path
    edit_usr_profile_path(@profile, source: "completed_profile", anchor: "credits_form")
  end
end
