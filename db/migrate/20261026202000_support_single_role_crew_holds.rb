class SupportSingleRoleCrewHolds < ActiveRecord::Migration[8.1]
  def up
    add_reference :crew_holds, :job, foreign_key: true
    execute "UPDATE crew_holds SET job_id = crew_positions.job_id FROM crew_positions WHERE crew_holds.crew_position_id = crew_positions.id"
    change_column_null :crew_holds, :job_id, false
    change_column_null :crew_holds, :crew_position_id, true
    add_index :crew_holds, [ :job_id, :crew_member_id ], unique: true, where: "crew_position_id IS NULL"
  end

  def down
    execute "DELETE FROM crew_holds WHERE crew_position_id IS NULL"
    remove_index :crew_holds, [ :job_id, :crew_member_id ]
    change_column_null :crew_holds, :crew_position_id, false
    remove_reference :crew_holds, :job, foreign_key: true
  end
end
