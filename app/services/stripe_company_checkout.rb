class StripeCompanyCheckout
  class InvalidSelection < StandardError; end

  INTERVALS = %w[monthly annual].freeze

  def initialize(company:, owner:, plan:, interval:, success_url:, cancel_url:, price_catalog: StripePriceCatalog.company)
    @company = company
    @owner = owner
    @plan = plan
    @interval = interval.to_s
    @success_url = success_url
    @cancel_url = cancel_url
    @price_catalog = price_catalog
  end

  def call
    validate_selection!

    Stripe::Checkout::Session.create(session_parameters, { idempotency_key: idempotency_key })
  end

  private

  attr_reader :company, :owner, :plan, :interval, :success_url, :cancel_url, :price_catalog

  def validate_selection!
    raise InvalidSelection, "That billing plan is unavailable." unless plan&.active?
    raise InvalidSelection, "Choose monthly or annual billing." unless INTERVALS.include?(interval)
    raise InvalidSelection, "Stripe pricing is not configured for that plan." if stripe_price_id.blank?
  end

  def session_parameters
    metadata = {
      "company_id" => company.id.to_s,
      "plan_id" => plan.id.to_s,
      "billing_interval" => interval
    }

    {
      mode: "subscription",
      line_items: [ { price: stripe_price_id, quantity: 1 } ],
      success_url:,
      cancel_url:,
      client_reference_id: company.id.to_s,
      allow_promotion_codes: true,
      billing_address_collection: "required",
      metadata:,
      subscription_data: { metadata: }
    }.merge(customer_parameters)
  end

  def customer_parameters
    return { customer: company.stripe_customer_id } if company.stripe_customer_id.present?

    { customer_email: owner.email }
  end

  def stripe_price_id
    @stripe_price_id ||= configured_plan_price_id.presence || price_catalog[[ plan.key, interval ]]
  end

  def configured_plan_price_id
    interval == "annual" ? plan.stripe_annual_price_id : plan.stripe_monthly_price_id
  end

  def idempotency_key
    "company-checkout:#{company.id}:#{plan.id}:#{interval}:#{Time.current.utc.strftime('%Y%m%d%H')}"
  end
end
