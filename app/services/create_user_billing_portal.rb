class CreateUserBillingPortal
  Result = Data.define(:success, :url, :error) do
    def success? = success
  end

  def initialize(user:, subscription:, return_url:, gateway: Stripe::BillingPortal::Session)
    @user = user
    @subscription = subscription
    @return_url = return_url
    @gateway = gateway
  end

  def call
    return failure("No Stripe billing profile is connected to this account.") if subscription&.stripe_customer_id.blank?

    session = gateway.create(
      customer: subscription.stripe_customer_id,
      return_url:
    )
    Result.new(success: true, url: session.url, error: nil)
  rescue Stripe::StripeError => error
    Rails.error.report(error, context: { user_id: user.id })
    failure("Stripe could not open billing management. Please try again.")
  end

  private

  attr_reader :user, :subscription, :return_url, :gateway

  def failure(error)
    Result.new(success: false, url: nil, error:)
  end
end
