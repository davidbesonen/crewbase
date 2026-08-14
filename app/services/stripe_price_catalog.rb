class StripePriceCatalog
  class << self
    def company
      Plan.active.each_with_object({}) do |plan, catalog|
        catalog[[ plan.key, "monthly" ]] = plan.stripe_monthly_price_id.presence
        catalog[[ plan.key, "annual" ]] = plan.stripe_annual_price_id.presence
      end
    end
  end
end
