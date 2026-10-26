class Usr::UserBlocksController < ApplicationController
  def create
    profile = Profile.network_visible.find(params.require(:user_block).permit(:profile_id)[:profile_id])
    BlockUser.new(blocker: current_user, blocked_user: profile.user).call
    redirect_to usr_profile_path(profile), notice: "Person blocked. Existing job conversations remain available for coordination and reporting."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to usr_reports_path, alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    block = UserBlock.where(blocker: current_user).find(params[:id])
    UnblockUser.new(block:).call
    redirect_to usr_reports_path, notice: "Person unblocked. Previous connections have not been restored."
  end
end
