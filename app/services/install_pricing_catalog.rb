class InstallPricingCatalog
  def call
    Plan.transaction do
      PricingCatalog.definitions.each do |attributes|
        plan = Plan.find_or_initialize_by(key: attributes.fetch(:key))
        plan.update!(attributes)
      end
      Plan.where.not(key: PricingCatalog.definitions.pluck(:key)).or(Plan.where(key: nil)).update_all(active: false)
      UserPlan.where(active: true).update_all(active: false)
    end
  end
end
