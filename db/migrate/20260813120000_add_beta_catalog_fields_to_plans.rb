class AddBetaCatalogFieldsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :key, :string
    add_column :plans, :description, :text
    add_column :plans, :position, :integer, null: false, default: 0
    add_column :plans, :active, :boolean, null: false, default: true

    add_index :plans, :key, unique: true
  end
end
