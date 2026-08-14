class Plan < ApplicationRecord
  TIER_RANKS = { "starter" => 0, "team" => 1, "studio" => 2 }.freeze
  COMPANY_FEATURES = {
    crew_marketplace: { label: "Full crew marketplace", icon: "bi-globe2", minimum_tier: "starter" },
    applications_invitations: { label: "Applications and invitations", icon: "bi-send-check", minimum_tier: "starter" },
    live_messaging: { label: "Live contextual messaging", icon: "bi-chat-dots", minimum_tier: "starter" },
    crew_recommendations: { label: "Crew recommendations", icon: "bi-stars", minimum_tier: "starter" },
    multi_position_gigs: { label: "Multi-position gig staffing", icon: "bi-diagram-3", minimum_tier: "team" },
    shortlists_pipeline: { label: "Shortlists and applicant pipeline", icon: "bi-ui-checks-grid", minimum_tier: "team" },
    availability_matching: { label: "Availability and conflict matching", icon: "bi-calendar2-check", minimum_tier: "team" },
    calendar_sync: { label: "Calendar-aware staffing", icon: "bi-calendar3", minimum_tier: "team" },
    staffing_analytics: { label: "Staffing analytics", icon: "bi-graph-up-arrow", minimum_tier: "team" },
    priority_support: { label: "Priority support and onboarding", icon: "bi-headset", minimum_tier: "studio" },
    enhanced_visibility: { label: "Enhanced company visibility", icon: "bi-megaphone", minimum_tier: "studio" },
    integrations: { label: "Early access to integrations", icon: "bi-plug", minimum_tier: "studio" }
  }.freeze

  has_many :company_plans, dependent: :destroy
  has_many :companies, through: :company_plans
  before_validation :set_default_key

  validates :key, :name, presence: true
  validates :key, uniqueness: true
  validates :monthly_price_cents, :annual_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_monthly_price_id, :stripe_annual_price_id, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true).order(:position, :id) }

  def monthly_price
    formatted_price(monthly_price_cents)
  end

  def annual_price
    formatted_price(annual_price_cents)
  end

  def feature_list
    limits = data || {}
    [
      limit_label(limits["seats_limit"], "company user"),
      limit_label(limits["active_jobs_limit"], "active job"),
      limit_label(limits["projects_limit"], "active project")
    ].compact + Array(limits["features"])
  end

  def capacity_items
    limits = data || {}
    [
      { label: limit_label(limits["seats_limit"], "company user"), icon: "bi-people" },
      { label: limit_label(limits["active_jobs_limit"], "active job"), icon: "bi-briefcase" },
      { label: limit_label(limits["projects_limit"], "active project"), icon: "bi-kanban" }
    ].compact_blank
  end

  def feature_matrix
    COMPANY_FEATURES.map do |key, feature|
      feature.merge(key:, included: tier_rank >= TIER_RANKS.fetch(feature.fetch(:minimum_tier)))
    end
  end

  private

  def set_default_key
    self.key ||= name.to_s.parameterize.presence
  end

  def formatted_price(cents)
    dollars = cents.to_i / 100.0
    "$#{dollars % 1 == 0 ? dollars.to_i : format('%.2f', dollars)}"
  end

  def tier_rank
    TIER_RANKS.fetch(key, 0)
  end

  def limit_label(limit, label)
    return if limit.blank?
    return "Unlimited #{label.pluralize}" if limit == "unlimited"

    "#{limit} #{label.pluralize(limit)}"
  end
end
