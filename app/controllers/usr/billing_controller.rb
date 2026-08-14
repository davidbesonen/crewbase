class Usr::BillingController < ApplicationController
  def show
    @plans = UserPlan.active.to_a
    @subscription = current_subscription
  end

  def subscription_checkout
    plan = UserPlan.active.find(params[:user_plan_id])
    result = CreateUserSubscriptionCheckout.new(
      user: current_user,
      plan:,
      billing_interval: params[:billing_interval],
      stripe_customer_id: current_subscription&.stripe_customer_id,
      success_url: usr_settings_billing_url(checkout: "success"),
      cancel_url: usr_settings_billing_url
    ).call

    redirect_to result.success? ? result.url : usr_settings_billing_path,
      allow_other_host: result.success?,
      alert: result.error
  end

  def portal
    result = CreateUserBillingPortal.new(
      user: current_user,
      subscription: current_subscription,
      return_url: usr_settings_billing_url
    ).call

    redirect_to result.success? ? result.url : usr_settings_billing_path,
      allow_other_host: result.success?,
      alert: result.error
  end

  private

  def current_subscription
    @current_subscription ||= current_user.user_subscriptions.current.includes(:user_plan).first
  end
end
