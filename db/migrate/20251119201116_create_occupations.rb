class CreateOccupations < ActiveRecord::Migration[8.0]
  def change
    create_table :occupations do |t|
      t.string :name
      t.integer :industry_id

      t.timestamps
    end
  end
end
