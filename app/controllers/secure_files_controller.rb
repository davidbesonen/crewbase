class SecureFilesController < ApplicationController
  include SecureFileDelivery
  skip_before_action :authenticate_user!, only: :show

  def show
    blob = ActiveStorage::Blob.find_signed!(params[:signed_id])
    raise ActiveRecord::RecordNotFound unless FileAccess.new(blob:, user: current_user).allowed?

    deliver_file(blob, inline: params[:inline] == "1")
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveStorage::FileNotFoundError
    head :not_found
  end
end
