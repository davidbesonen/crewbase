class Admin::BillingController < Admin::BaseController
  def show
    @pagy, @subscriptions = pagy(Admin::BillingAccounts.new(params: params).results)
    @attention_count = CompanyPlan.where(status: %w[past_due unpaid incomplete paused]).count
    @unprocessed_count = StripeEvent.where(processed_at: nil).count
  end
end
