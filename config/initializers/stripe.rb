if Rails.configuration.x.demo_mode
  Stripe.api_key = nil
else
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"].presence || Rails.application.credentials.dig(:stripe, :secret_key)
end
