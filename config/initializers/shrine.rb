require "shrine"
require "shrine/storage/file_system"

if ENV["S3_BUCKET"].present?
  require "shrine/storage/s3"
  options = {
    bucket: ENV.fetch("S3_BUCKET"), region: ENV.fetch("S3_REGION", "us-east-2"),
    endpoint: ENV["S3_ENDPOINT"], force_path_style: true,
    access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"), secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY")
  }.compact
  Shrine.storages = {
    cache: Shrine::Storage::S3.new(**options, prefix: "image-cache"),
    store: Shrine::Storage::S3.new(**options, prefix: "images")
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("storage", prefix: "image-cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads")
  }
end

Shrine.plugin :activerecord           # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data    # extracts metadata for assigned cached files
