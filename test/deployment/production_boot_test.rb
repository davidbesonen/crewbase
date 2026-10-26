require "test_helper"
require "open3"

class ProductionBootTest < ActiveSupport::TestCase
  test "production eager loading boots with only the authorized attachment routes" do
    script = <<~RUBY
      abort "Demo disabled" unless Rails.configuration.x.demo_mode
      abort "Email enabled" if ActionMailer::Base.perform_deliveries
      abort "Payments enabled" if Stripe.api_key.present?
      abort "Public attachment routes enabled" if ActiveStorage.draw_routes
      abort "Wrong file controller" unless Rails.application.routes.recognize_path("/files/signed/example.txt")[:controller] == "secure_files"
      puts "production-demo-ready"
    RUBY
    output, status = Open3.capture2e(
      { "RAILS_ENV" => "production", "CREWBASE_DEMO" => "true", "SECRET_KEY_BASE_DUMMY" => "1", "SOLID_QUEUE_IN_PUMA" => nil },
      "bin/rails", "runner", script, chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, "production-demo-ready"
  end
end
