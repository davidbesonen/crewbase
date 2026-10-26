class UploadsController < ApplicationController
  def create
    file = params[:file]
    return render json: { error: "Select a file." }, status: :unprocessable_entity unless file.is_a?(ActionDispatch::Http::UploadedFile)

    blob = ActiveStorage::Blob.create_and_upload!(io: file.tempfile, filename: file.original_filename,
      metadata: { uploader_id: current_user.id })
    render json: { sgid: blob.attachable_sgid, url: rails_service_blob_path(blob.signed_id, blob.filename, inline: "1"),
      href: rails_service_blob_path(blob.signed_id, blob.filename) }
  end
end
