class StripeCompanySubscriptionChange
  def initialize(company_plan:, stripe_price_id:, plan: nil, billing_interval: nil)
    @company_plan = company_plan
    @plan = plan
    @billing_interval = billing_interval
    @stripe_price_id = stripe_price_id
  end

  def call
    Stripe::Subscription.update(
      company_plan.stripe_subscription_id,
      {
        items: [ { id: company_plan.stripe_subscription_item_id, price: stripe_price_id } ],
        proration_behavior: "always_invoice",
        payment_behavior: "pending_if_incomplete"
      }.merge(metadata_parameters),
      { idempotency_key: idempotency_key }
    )
  end

  private

  attr_reader :company_plan, :plan, :billing_interval, :stripe_price_id

  def metadata_parameters
    return {} unless plan && billing_interval

    {
      metadata: {
        company_id: company_plan.company_id.to_s,
        plan_id: plan.id.to_s,
        billing_interval:
      }
    }
  end

  def idempotency_key
    "company-subscription-change:#{company_plan.stripe_subscription_id}:#{stripe_price_id}:#{Time.current.utc.strftime('%Y%m%d%H')}"
  end
end
