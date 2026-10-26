require "test_helper"
require "yaml"
require "erb"
require "open3"

class RenderConfigurationTest < ActiveSupport::TestCase
  test "Puma runs the hosted queue in threads instead of forking extra Ruby processes" do
    script = <<~RUBY
      require "puma"
      require "puma/configuration"
      config = Puma::Configuration.new(config_files: ["config/puma.rb"])
      config.load
      config.clamp
      abort "Queue plugin still forks" unless config.options[:solid_queue_mode] == :async
      puts "single-process-queue"
    RUBY
    output, status = Open3.capture2e(
      { "SOLID_QUEUE_IN_PUMA" => "true", "SOLID_QUEUE_SUPERVISOR_MODE" => "async" },
      "bundle", "exec", "ruby", "-e", script, chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, "single-process-queue"
  end

  test "production database preparation never runs destructive development seeds" do
    config = YAML.safe_load(ERB.new(Rails.root.join("config/database.yml").read).result, aliases: true)
    config.fetch("production").each_value { |database| assert_equal false, database.fetch("seeds", true) }
  end

  test "the threaded queue has enough database connections for workers and supervision" do
    config = YAML.safe_load(ERB.new(Rails.root.join("config/database.yml").read).result, aliases: true)
    assert_operator config.fetch("production").fetch("queue").fetch("pool"), :>=, 10
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
