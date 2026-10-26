# Versioned keys preserve existing subscriptions and their Stripe price mappings.
# Publish a new key when changing a paid price; never repoint an existing price.
class PricingCatalog
  def self.plans
    definitions.map { |attributes| Plan.new(attributes) }
  end

  def self.definitions
    [
      { key: "free", name: "Starter", position: 1, active: true,
        description: "For occasional hiring. Start with two open jobs and no payment details.",
        monthly_price_cents: 0, annual_price_cents: 0,
        data: { billing_scope: "company", seats_limit: 2, active_jobs_limit: 2, projects_limit: 1 } },
      { key: "team_2026", name: "Team", position: 2, active: true,
        description: "For teams coordinating recurring work, multiple roles, and crew schedules.",
        monthly_price_cents: 1900, annual_price_cents: 19000,
        data: { billing_scope: "company", seats_limit: 5, active_jobs_limit: 15, projects_limit: "unlimited" } }
    ]
  end
end
