class Usr::NetworksController < ApplicationController
  include NetworkAccess

  def show
    @tab = params[:tab].presence_in(CrewNetwork::TABS) || "connections"
    @query = params[:q].to_s.strip.first(100)
    network = CrewNetwork.new(user: current_user)
    @pending_count = network.pending_count
    rows = network.rows(tab: @tab, query: @query)
    @pagy = Pagy.new(count: rows.size, page: params[:page], limit: 24)
    @rows = rows.slice(@pagy.offset, @pagy.limit) || []
    @shared_jobs = current_user.received_network_job_shares
      .includes(:sender, job: :company).order(created_at: :desc).limit(5).to_a
  end
end
