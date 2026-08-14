class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :monthly_price_cents
      t.integer :annual_price_cents
      t.jsonb :data

      t.timestamps
    end
  end
end
