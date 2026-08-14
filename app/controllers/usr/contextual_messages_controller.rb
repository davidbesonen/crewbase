class Usr::ContextualMessagesController < ApplicationController
  before_action :set_context

  def create
    message = ContextualMessageCreator.new(
      context: @context,
      sender: current_user,
      body: message_params[:body]
    ).call

    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { redirect_to usr_conversation_path(message.conversation), notice: "Message sent." }
    end
  rescue ContextualMessageCreator::NotAuthorized
    raise ActiveRecord::RecordNotFound
  end

  private

  def set_context
    @context =
      if params[:conversation_id]
        current_user.conversations.find(params[:conversation_id]).context
      elsif params[:job_application_id]
        JobApplication.find(params[:job_application_id])
      else
        JobInvitation.find(params[:job_invitation_id])
      end
  end

  def message_params
    params.require(:contextual_message).permit(:body)
  end
end
