module SecureFileDelivery
  extend ActiveSupport::Concern

  private

  def deliver_file(blob, inline: false)
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"
    disposition = inline && UploadPolicy::IMAGE_TYPES.include?(blob.content_type) ? "inline" : "attachment"
    send_data blob.download, filename: blob.filename.to_s, type: blob.content_type, disposition:
  end
end
