class Admin::CompaniesQuery
  def initialize(params:)
    @params = params
  end

  def results
    scope = Company.includes(:users, :jobs, company_plans: :plan).order(created_at: :desc, id: :desc)
    params[:q].present? ? scope.where("companies.name ILIKE ?", "%#{Company.sanitize_sql_like(params[:q])}%") : scope
  end

  private

  attr_reader :params
end
