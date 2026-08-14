class StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_before_action :set_unread_notification_count
  skip_before_action :set_projects_navigation_path

  def create
    event = Stripe::Webhook.construct_event(
      request.raw_post,
      request.headers["Stripe-Signature"],
      webhook_secret
    )
    ProcessStripeEvent.new(event:).call
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  private

  def webhook_secret
    ENV["STRIPE_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:stripe, :webhook_secret).to_s
  end
end
