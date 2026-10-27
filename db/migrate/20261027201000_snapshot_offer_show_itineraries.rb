class SnapshotOfferShowItineraries < ActiveRecord::Migration[8.1]
  def change
    add_column :job_offers, :show_itinerary, :jsonb, null: false, default: []
  end
end
