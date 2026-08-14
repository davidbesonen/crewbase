class CreateSkillAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :skill_assignments do |t|
      t.integer :skill_id
      t.integer :profile_id

      t.timestamps
    end
  end
end
