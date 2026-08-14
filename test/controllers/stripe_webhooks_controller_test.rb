require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "rejects a webhook with an invalid signature" do
    post stripe_webhook_path,
      params: "{}",
      headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "invalid" }

    assert_response :bad_request
  end

  test "accepts a verified webhook without user authentication" do
    event = Stripe::Event.construct_from("id" => "evt_controller", "type" => "unhandled.event", "data" => { "object" => {} })
    processor = Object.new
    processor.define_singleton_method(:call) { true }

    with_singleton_method(Stripe::Webhook, :construct_event, ->(*) { event }) do
      with_singleton_method(ProcessStripeEvent, :new, ->(**) { processor }) do
        post stripe_webhook_path,
          params: "{}",
          headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "valid" }
      end
    end

    assert_response :ok
  end

  private

  def with_singleton_method(target, method_name, replacement)
    singleton = target.singleton_class
    original = singleton.instance_method(method_name)
    singleton.define_method(method_name, replacement)
    yield
  ensure
    singleton.define_method(method_name, original)
  end
end
