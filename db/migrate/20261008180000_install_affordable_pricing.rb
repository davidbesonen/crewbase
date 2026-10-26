class InstallAffordablePricing < ActiveRecord::Migration[8.1]
  def up
    InstallPricingCatalog.new.call
  end

  def down
    # Catalog retirement is reversible, but subscriptions must never be rewritten.
    Plan.where(key: %w[free team_2026]).update_all(active: false)
    Plan.where(key: %w[starter team studio]).update_all(active: true)
  end
end
