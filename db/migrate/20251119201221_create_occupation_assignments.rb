class CreateOccupationAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :occupation_assignments do |t|
      t.integer :occupation_id
      t.integer :profile_id

      t.timestamps
    end

    add_index :occupation_assignments, [ :occupation_id, :profile_id ], unique: true
  end
end
