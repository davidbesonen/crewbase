class Usr::CompanyBillingPortalsController < ApplicationController
  before_action :set_owned_company

  def create
    session = StripeCustomerPortal.new(
      company: @company,
      return_url: usr_company_plan_url(@company)
    ).call

    redirect_to session.url, allow_other_host: true
  rescue StripeCustomerPortal::CustomerMissing => error
    redirect_to usr_company_plan_path(@company), alert: error.message
  end

  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end
end
