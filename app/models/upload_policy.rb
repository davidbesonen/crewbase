class UploadPolicy
  MAX_FILE_SIZE = 35.megabytes
  IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  CONTENT_TYPES = (IMAGE_TYPES + %w[
    application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.presentationml.presentation application/vnd.ms-powerpoint
    application/vnd.oasis.opendocument.text application/vnd.oasis.opendocument.spreadsheet
    application/rtf text/rtf text/plain text/csv
  ]).freeze
  EXTENSIONS = %w[pdf doc docx xls xlsx ppt pptx odt ods rtf txt csv jpg jpeg png webp gif].freeze

  def self.validate(record, attribute, blob)
    errors_for(size: blob.byte_size, filename: blob.filename.to_s, content_type: blob.content_type).each do |error|
      record.errors.add(attribute, error)
    end
  end

  def self.errors_for(size:, filename:, content_type:)
    errors = []
    errors << "must be 35 MB or smaller" if size > MAX_FILE_SIZE
    unless CONTENT_TYPES.include?(content_type) && EXTENSIONS.include?(File.extname(filename).delete_prefix(".").downcase)
      errors << "must be a supported document or image"
    end
    errors
  end
end
