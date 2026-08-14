class CreateLocationAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :location_assignments do |t|
      t.integer :location_id
      t.integer :locationable_id
      t.string :locationable_type

      t.timestamps
    end
  end
end
