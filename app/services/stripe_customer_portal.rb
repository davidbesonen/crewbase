class StripeCustomerPortal
  class CustomerMissing < StandardError; end

  def initialize(company:, return_url:)
    @company = company
    @return_url = return_url
  end

  def call
    raise CustomerMissing, "Complete checkout before managing billing." if company.stripe_customer_id.blank?

    Stripe::BillingPortal::Session.create(customer: company.stripe_customer_id, return_url:)
  end

  private

  attr_reader :company, :return_url
end
