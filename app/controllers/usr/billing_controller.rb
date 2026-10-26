class Usr::BillingController < ApplicationController
  def show
    @subscription = current_subscription
  end

  def subscription_checkout
    redirect_to usr_settings_billing_path, notice: "Crew accounts are free. No subscription is needed."
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
    @current_subscription ||= current_user.user_subscriptions.includes(:user_plan).order(created_at: :desc, id: :desc).first
  end
end
