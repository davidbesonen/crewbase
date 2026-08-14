class Usr::CompanyBillingCheckoutsController < ApplicationController
  before_action :set_owned_company

  def create
    plan = Plan.active.find(params[:plan_id])
    existing_subscription = @company.company_plans
      .where(status: CompanyPlan::ENTITLED_STATUSES + [ "past_due" ])
      .where.not(stripe_subscription_id: nil)
      .order(created_at: :desc, id: :desc)
      .first
    return change_existing_subscription(existing_subscription, plan) if existing_subscription

    session = StripeCompanyCheckout.new(
      company: @company,
      owner: current_user,
      plan:,
      interval: params[:billing_interval],
      success_url: usr_company_plan_url(@company, checkout: "success", session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: usr_company_plan_url(@company, checkout: "cancelled")
    ).call

    redirect_to session.url, allow_other_host: true
  rescue StripeCompanyCheckout::InvalidSelection => error
    redirect_to usr_company_plan_path(@company), alert: error.message
  end

  private

  def change_existing_subscription(company_plan, plan)
    stripe_price_id = if params[:billing_interval].to_s == "annual"
      plan.stripe_annual_price_id
    else
      plan.stripe_monthly_price_id
    end
    stripe_price_id ||= StripePriceCatalog.company[[ plan.key, params[:billing_interval].to_s ]]
    raise StripeCompanyCheckout::InvalidSelection, "Stripe pricing is not configured for that plan." if stripe_price_id.blank?

    StripeCompanySubscriptionChange.new(
      company_plan:,
      plan:,
      billing_interval: params[:billing_interval].to_s,
      stripe_price_id:
    ).call
    redirect_to usr_company_plan_path(@company), notice: "Your plan change is being finalized. Access updates after Stripe confirms payment."
  end

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end
end
