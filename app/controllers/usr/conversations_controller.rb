class Usr::ConversationsController < ApplicationController
  before_action :set_membership, only: :show

  def index
    @conversations = ConversationInbox.new(user: current_user).results
  end

  def show
    @conversation = @membership.conversation
    @messages = @conversation.messages.includes(:sender).order(:created_at, :id)
    ConversationReader.new(membership: @membership).call
  end

  private

  def set_membership
    @membership = current_user.conversation_memberships
      .includes(conversation: [ :context, memberships: :user ])
      .find_by!(conversation_id: params[:id])
  end
end
