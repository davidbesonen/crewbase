require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Crewbase
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = "Central Time (US & Canada)"

    config.autoload_paths += Dir[Rails.root.join("app", "models", "{*/}")]
    config.eager_load_paths += %W[ #{config.root}/app/services #{config.root}/app/models/concerns/ ]
    config.importmap.paths += Dir[Rails.root.join("config", "importmaps", "{*.rb}")]
    Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].each { |l| require l }

    config.generators.template_engine = "haml"
    config.generators do |g|
      g.view_component base_class: "ApplicationComponent"
    end

    config.importmap.paths += Dir[Rails.root.join("config", "importmaps", "{*.rb}")]

    # View Component fix for form bugs
    config.view_component.capture_compatibility_patch_enabled = true
    config.view_component.default_preview_layout = "component_preview"
    config.view_component.show_previews = Rails.env.development?

    # Set SolidQueue as the ActiveJob queue adapter
    # TODO: Need to implement
    # config.active_job.queue_adapter = :solid_queue
    # config.mission_control.jobs.base_controller_class = "AdminController"
    # config.mission_control.jobs.http_basic_auth_enabled = false

    # config.payment_vendor = :stripe
  end
end
