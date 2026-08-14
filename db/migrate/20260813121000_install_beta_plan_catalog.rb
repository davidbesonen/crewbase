class InstallBetaPlanCatalog < ActiveRecord::Migration[8.0]
  class PlanRecord < ActiveRecord::Base
    self.table_name = "plans"
  end

  CATALOG = [
    {
      key: "starter", name: "Starter", description: "For small production teams hiring a few roles at a time.",
      position: 1, monthly_price_cents: 1_900, annual_price_cents: 19_000,
      data: { billing_scope: "company", seats_limit: 2, active_jobs_limit: 3, projects_limit: 2,
        features: [ "Full crew marketplace", "Applications, invitations, and live messaging", "Basic crew recommendations" ] }
    },
    {
      key: "team", name: "Team", description: "The complete staffing workflow for growing event teams.",
      position: 2, monthly_price_cents: 4_900, annual_price_cents: 49_000,
      data: { billing_scope: "company", seats_limit: 8, active_jobs_limit: 15, projects_limit: "unlimited",
        features: [ "Multi-position gig staffing", "Shortlists and applicant pipeline", "Availability and conflict matching", "Calendar-aware staffing", "Basic staffing analytics" ] }
    },
    {
      key: "studio", name: "Studio", description: "For high-volume production organizations that need more capacity and support.",
      position: 3, monthly_price_cents: 9_900, annual_price_cents: 99_000,
      data: { billing_scope: "company", seats_limit: 25, active_jobs_limit: "unlimited", projects_limit: "unlimited",
        features: [ "Advanced staffing analytics", "Priority support and onboarding", "Enhanced company visibility", "Early access to integrations" ] }
    }
  ].freeze

  def up
    PlanRecord.reset_column_information
    PlanRecord.where(key: nil).find_each do |plan|
      plan.update_columns(key: "legacy-#{plan.id}", active: false)
    end

    CATALOG.each do |attributes|
      plan = PlanRecord.find_or_initialize_by(key: attributes.fetch(:key))
      plan.update!(attributes.merge(active: true))
    end
  end

  def down
    PlanRecord.where(key: CATALOG.pluck(:key)).where.not(id: company_plan_ids).delete_all
  end

  private

  def company_plan_ids
    connection.select_values("SELECT DISTINCT plan_id FROM company_plans").map(&:to_i)
  end
end
