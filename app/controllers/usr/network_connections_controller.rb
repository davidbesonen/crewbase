class Usr::NetworkConnectionsController < ApplicationController
  include NetworkAccess
  before_action :set_recipient_profile, only: [ :new, :create ]

  def new
    @connection = NetworkConnection.new
  end

  def create
    @connection = RequestNetworkConnection.new(sender: current_user, recipient: @profile.user,
      introduction: connection_params[:introduction]).call
    redirect_to usr_network_path(tab: "requests"), notice: "Connection request saved. You can manage your requests here."
  rescue ActiveRecord::RecordInvalid => error
    @connection = error.record
    render :new, status: :unprocessable_entity
  end

  def accept
    respond_to_request(accept: true)
  end

  def decline
    respond_to_request(accept: false)
  end

  def destroy
    connection = NetworkConnection.involving(current_user)
      .where("status = :accepted OR (status = :pending AND sender_id = :user_id)",
        accepted: NetworkConnection.statuses[:accepted], pending: NetworkConnection.statuses[:pending], user_id: current_user.id)
      .find(params[:id])
    connection.with_lock { connection.destroy! }
    redirect_to usr_network_path, notice: "Connection or request removed."
  end

  private

  def set_recipient_profile
    @profile = Profile.network_visible.includes(:user).find(params[:profile_id] || connection_params[:profile_id])
    raise ActiveRecord::RecordNotFound if UserBlock.between?(current_user, @profile.user)
  end

  def connection_params
    params.require(:network_connection).permit(:profile_id, :introduction)
  end

  def respond_to_request(accept:)
    connection = current_user.received_network_connections.find(params[:id])
    RespondToNetworkConnection.new(connection:, recipient: current_user, accept:).call
    redirect_to usr_network_path(tab: accept ? "connections" : "requests"), notice: accept ? "Connection accepted." : "Request declined."
  end
end
