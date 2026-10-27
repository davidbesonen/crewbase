class CreateVenueCatalogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_catalog_entries do |t|
      t.string :source_key, null: false
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country, default: "US", null: false
      t.string :category
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.text :search_text, null: false
      t.timestamps
    end
    add_index :venue_catalog_entries, :source_key, unique: true
    add_index :venue_catalog_entries, :search_text, using: :gin, opclass: :gin_trgm_ops
    add_reference :venues, :venue_catalog_entry, foreign_key: true
  end
end
