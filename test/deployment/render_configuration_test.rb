require "test_helper"
require "yaml"
require "erb"

class RenderConfigurationTest < ActiveSupport::TestCase
  test "production database preparation never runs destructive development seeds" do
    config = YAML.safe_load(ERB.new(Rails.root.join("config/database.yml").read).result, aliases: true)
    config.fetch("production").each_value { |database| assert_equal false, database.fetch("seeds", true) }
  end

  test "render blueprint uses a free web service and generated demo secrets" do
    path = Rails.root.join("render.yaml")
    assert path.exist?, "Render deployment blueprint is missing"
    service = YAML.safe_load(path.read).fetch("services").first
    assert_equal "free", service.fetch("plan")
    env = service.fetch("envVars").index_by { |item| item.fetch("key") }
    assert_equal "0", env.fetch("WEB_CONCURRENCY").fetch("value")
    assert_equal "async", env.fetch("SOLID_QUEUE_SUPERVISOR_MODE").fetch("value")
    assert env.fetch("SECRET_KEY_BASE").fetch("generateValue")
    assert env.fetch("DEMO_OWNER_PASSWORD").fetch("generateValue")
    assert_not env.key?("RAILS_MASTER_KEY"), "The demo must not inherit production credentials"
  end
end
