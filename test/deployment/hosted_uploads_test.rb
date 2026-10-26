require "test_helper"
require "yaml"
require "erb"

class HostedUploadsTest < ActiveSupport::TestCase
  test "hosted upload configuration keeps both upload systems off the ephemeral disk" do
    values = { "S3_BUCKET" => "demo-uploads", "S3_REGION" => "us-east-2",
      "S3_ENDPOINT" => "https://storage.example.com", "S3_ACCESS_KEY_ID" => "test-key", "S3_SECRET_ACCESS_KEY" => "test-secret" }
    old_env = values.keys.to_h { |key| [ key, ENV[key] ] }
    old_storages = Shrine.storages
    values.each { |key, value| ENV[key] = value }
    load Rails.root.join("config/initializers/shrine.rb")
    assert_equal "Shrine::Storage::S3", Shrine.storages.fetch(:store).class.name
    assert_equal "Shrine::Storage::S3", Shrine.storages.fetch(:cache).class.name
    url = Shrine.storages.fetch(:store).url("example.png")
    assert_includes url, "storage.example.com/demo-uploads/"
    assert_includes url, "X-Amz-Signature="
    configuration = YAML.safe_load(ERB.new(Rails.root.join("config/storage.yml").read).result)
    assert_equal "S3", configuration.fetch("hosted").fetch("service")
    assert_equal "demo-uploads", configuration.fetch("hosted").fetch("bucket")
  ensure
    old_env&.each { |key, value| ENV[key] = value }
    Shrine.storages = old_storages if old_storages
  end
end
