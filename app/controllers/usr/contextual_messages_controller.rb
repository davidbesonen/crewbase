class Usr::ContextualMessagesController < ApplicationController
  before_action :set_context

  def create
    message = ContextualMessageCreator.new(
      context: @context,
      sender: current_user,
      body: message_params[:body],
      files: message_params[:files] || []
    ).call

    respond_to do |format|
      format.turbo_stream do
        if params[:conversation_id]
          render turbo_stream: turbo_stream.append(helpers.dom_id(message.conversation, :messages),
            Usr::ConversationMessageComponent.new(message:, current_user:))
        else
          redirect_to usr_conversation_path(message.conversation), status: :see_other
        end
      end
      format.html { redirect_to usr_conversation_path(message.conversation), notice: "Message sent." }
    end
  rescue ContextualMessageCreator::Archived, ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(params[:conversation_id] ? "message-errors" : "upload-errors", helpers.tag.div(error.message, class: "alert alert-warning", role: "alert")), status: :unprocessable_entity
      end
      format.html { redirect_to failure_path, alert: error.message }
    end
  rescue ContextualMessageCreator::NotAuthorized
    raise ActiveRecord::RecordNotFound
  end

  private

  def failure_path
    return usr_conversation_path(@context.conversation) if @context.conversation

    @context.is_a?(JobApplication) ? usr_job_application_path(@context) : usr_job_invitations_path
  end

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
    params.require(:contextual_message).permit(:body, files: [])
  end
end
