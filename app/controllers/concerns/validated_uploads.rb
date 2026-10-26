module ValidatedUploads
  extend ActiveSupport::Concern

  FILE_FIELDS = %w[file files resume cover_letter_file attachments image].freeze

  included do
    before_action :validate_incoming_uploads
  end

  private

  def validate_incoming_uploads
    validate_upload_values(request.request_parameters)
  rescue ArgumentError => error
    respond_to do |format|
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(params[:conversation_id] ? "message-errors" : "upload-errors", helpers.tag.div(error.message, class: "alert alert-warning", role: "alert")), status: :unprocessable_entity
      end
      format.any { render plain: error.message, status: :unprocessable_entity }
    end
  end

  def validate_upload_values(value, field = nil)
    case value
    when ActionDispatch::Http::UploadedFile
      type = Marcel::MimeType.for(value.tempfile, name: value.original_filename)
      errors = UploadPolicy.errors_for(size: value.size, filename: value.original_filename, content_type: type)
      raise ArgumentError, "#{value.original_filename}: #{errors.to_sentence}" if errors.any?
    when Hash
      value.each { |key, item| validate_upload_values(item, key) }
    when Array
      value.each { |item| validate_upload_values(item, field) }
    when String
      # Only multipart files are accepted; a copied signed blob ID is not upload authorization.
      raise ArgumentError, "Please select a file from your device." if FILE_FIELDS.include?(field) && value.present?
    end
  end
end
