class CreateEquipmentAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_assignments do |t|
      t.integer :equipment_id
      t.integer :profile_id

      t.timestamps
    end
  end
end
