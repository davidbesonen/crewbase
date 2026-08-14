module CompanyFeatureEnforcement
  extend ActiveSupport::Concern

  private

  def require_company_feature!(company, feature)
    return if CompanyPlanEntitlement.new(company).allowed?(feature)

    label = Plan::COMPANY_FEATURES.fetch(feature).fetch(:label)
    redirect_to usr_company_path(company), alert: "#{label} requires a Team or Studio plan."
  end
end
