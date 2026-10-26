class ImageUploader < Shrine
  plugin :validation_helpers
  plugin :determine_mime_type, analyzer: ->(io, analyzers) { Marcel::MimeType.for(io) }

  Attacher.validate do
    validate_max_size UploadPolicy::MAX_FILE_SIZE, message: "must be 35 MB or smaller"
    validate_mime_type UploadPolicy::IMAGE_TYPES, message: "must be a JPEG, PNG, GIF, or WebP image"
  end
end
