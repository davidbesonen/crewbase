class CompanyPlanEntitlement
  CAPACITIES = {
    company_users: { data_key: "seats_limit", usage: :company_users_usage },
    seats: { data_key: "seats_limit", usage: :company_users_usage },
    active_jobs: { data_key: "active_jobs_limit", usage: :active_jobs_usage },
    active_projects: { data_key: "projects_limit", usage: :active_projects_usage },
    projects: { data_key: "projects_limit", usage: :active_projects_usage }
  }.freeze

  attr_reader :company

  def initialize(company)
    @company = company
  end

  def current_plan
    @current_plan ||= company.company_plans
      .current
      .first
      &.plan
  end

  def tier
    current_plan&.key
  end

  def allowed?(feature_key)
    feature = Plan::COMPANY_FEATURES[feature_key.to_sym]
    return false unless feature && tier

    current_tier_rank >= Plan::TIER_RANKS.fetch(feature.fetch(:minimum_tier))
  end

  def limit(capacity_key)
    capacity = capacity_for(capacity_key)
    return 0 unless capacity && current_plan

    normalize_limit(current_plan.data&.fetch(capacity.fetch(:data_key), nil))
  end

  def usage(capacity_key)
    capacity = capacity_for(capacity_key)
    return 0 unless capacity

    send(capacity.fetch(:usage))
  end

  def within_limit?(capacity_key)
    capacity_limit = limit(capacity_key)
    return true if capacity_limit == Float::INFINITY

    usage(capacity_key) < capacity_limit
  end

  private

  def capacity_for(key)
    CAPACITIES[key.to_sym]
  end

  def current_tier_rank
    Plan::TIER_RANKS.fetch(tier, -1)
  end

  def normalize_limit(value)
    return Float::INFINITY if value.to_s == "unlimited"

    value.to_i
  end

  def company_users_usage
    company.company_assignments.count
  end

  def active_jobs_usage
    company.jobs.where(is_active: true, status: :published).count
  end

  def active_projects_usage
    company.projects.active.where(status: %i[planning active]).count
  end
end
