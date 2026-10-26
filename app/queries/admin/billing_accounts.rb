class Admin::BillingAccounts
  def initialize(params:)
    @params = params
  end

  def results
    scope = CompanyPlan.includes(:company, :plan).order(created_at: :desc, id: :desc)
    scope = scope.where(status: @params[:status]) if CompanyPlan::STATUSES.include?(@params[:status])
    if @params[:q].present?
      query = "%#{Company.sanitize_sql_like(@params[:q])}%"
      scope = scope.joins(:company).where("companies.name ILIKE :q OR companies.contact_email ILIKE :q OR company_plans.stripe_subscription_id ILIKE :q", q: query)
    end
    scope
  end
end
