class CreateUserSubscriptionCheckout
  Result = Data.define(:success, :url, :error) do
    def success? = success
  end

  BILLING_INTERVALS = %w[monthly annual].freeze

  def initialize(user:, plan:, billing_interval:, success_url:, cancel_url:, stripe_customer_id: nil, gateway: Stripe::Checkout::Session)
    @user = user
    @plan = plan
    @billing_interval = billing_interval.to_s
    @success_url = success_url
    @cancel_url = cancel_url
    @stripe_customer_id = stripe_customer_id
    @gateway = gateway
  end

  def call
    return failure("Choose monthly or annual billing.") unless BILLING_INTERVALS.include?(billing_interval)
    return failure("The #{billing_interval} Stripe price is not configured yet.") if stripe_price_id.blank?

    session = gateway.create(checkout_attributes)
    Result.new(success: true, url: session.url, error: nil)
  rescue Stripe::StripeError => error
    Rails.error.report(error, context: { user_id: user.id, user_plan_id: plan.id })
    failure("Stripe could not start checkout. Please try again.")
  end

  private

  attr_reader :user, :plan, :billing_interval, :success_url, :cancel_url, :stripe_customer_id, :gateway

  def checkout_attributes
    {
      mode: "subscription",
      line_items: [ { price: stripe_price_id, quantity: 1 } ],
      success_url:,
      cancel_url:,
      allow_promotion_codes: true,
      metadata:,
      subscription_data: { metadata: }
    }.merge(customer_attributes)
  end

  def customer_attributes
    if stripe_customer_id.present?
      { customer: stripe_customer_id }
    else
      { customer_email: user.email }
    end
  end

  def metadata
    {
      "user_id" => user.id.to_s,
      "user_plan_id" => plan.id.to_s,
      "billing_interval" => billing_interval
    }
  end

  def stripe_price_id
    @stripe_price_id ||= plan.public_send("stripe_#{billing_interval}_price_id").presence
  end

  def failure(error)
    Result.new(success: false, url: nil, error:)
  end
end
