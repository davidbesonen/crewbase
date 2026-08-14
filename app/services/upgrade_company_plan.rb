class UpgradeCompanyPlan
  Result = Data.define(:success, :error) do
    def success? = success
  end

  def initialize(company:, plan:)
    @company = company
    @plan = plan
  end

  def call
    return failure("The selected plan is not available.") unless plan&.active?
    return failure("Choose a plan above #{current_plan.name}.") unless upgrade?

    CompanyPlan.transaction do
      current_subscription&.update!(status: "replaced", current_period_end: Time.current)
      company.company_plans.create!(
        plan:,
        status: "active",
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
    end

    Result.new(success: true, error: nil)
  end

  private

  attr_reader :company, :plan

  def current_subscription
    @current_subscription ||= company.company_plans.order(created_at: :desc, id: :desc).first
  end

  def current_plan
    current_subscription&.plan
  end

  def upgrade?
    return true unless current_plan

    tier_rank(plan) > tier_rank(current_plan)
  end

  def tier_rank(value)
    Plan::TIER_RANKS.fetch(value.key, -1)
  end

  def failure(message)
    Result.new(success: false, error: message)
  end
end
