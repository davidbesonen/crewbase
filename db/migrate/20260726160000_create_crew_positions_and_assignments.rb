class CreateCrewPositionsAndAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :crew_positions do |t|
      t.references :job, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :headcount, null: false, default: 1
      t.timestamps
    end

    create_table :crew_assignments do |t|
      t.references :crew_position, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.timestamps
    end
    add_index :crew_assignments, [ :crew_position_id, :profile_id ], unique: true
  end
end
