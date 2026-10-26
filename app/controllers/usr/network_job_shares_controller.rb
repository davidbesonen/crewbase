class Usr::NetworkJobSharesController < ApplicationController
  include NetworkAccess
  before_action :set_open_job, only: [ :new, :create ]
  before_action :set_connections, only: [ :new, :create ]

  def new
    @share = NetworkJobShare.new(recipient_id: params[:recipient_id])
  end

  def create
    recipient = NetworkConnection.connected_users(current_user).find(share_params[:recipient_id])
    @share = ShareNetworkJob.new(job: @job, sender: current_user, recipient:, note: share_params[:note]).call
    redirect_to usr_network_job_share_path(@share), notice: "Job shared with #{recipient.full_name}."
  rescue ActiveRecord::RecordInvalid => error
    @share = error.record
    render :new, status: :unprocessable_entity
  end

  def show
    @share = NetworkJobShare.involving(current_user).includes(:sender, :recipient, job: :company).find(params[:id])
  end

  private

  def set_open_job
    @job = Job.where(is_active: true, status: :published).includes(:company).find(params[:job_id])
    raise ActiveRecord::RecordNotFound unless @job.network_shareable?
  end

  def set_connections
    @recipients = NetworkConnection.connected_users(current_user).order(:first_name, :last_name).to_a
  end

  def share_params
    params.require(:network_job_share).permit(:recipient_id, :note)
  end
end
