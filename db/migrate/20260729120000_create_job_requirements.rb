class CreateJobRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :job_requirements do |t|
      t.references :job, null: false, foreign_key: true
      t.references :requirement, polymorphic: true, null: false
      t.integer :importance, null: false
      t.integer :source, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :job_requirements,
      [ :job_id, :requirement_type, :requirement_id, :importance ],
      unique: true,
      name: "index_job_requirements_on_job_requirement_and_importance"
    add_check_constraint :job_requirements,
      "requirement_type IN ('Occupation', 'Skill', 'Equipment')",
      name: "job_requirements_supported_requirement_type"
    add_check_constraint :job_requirements,
      "importance IN (0, 1)",
      name: "job_requirements_valid_importance"
    add_check_constraint :job_requirements,
      "source IN (0, 1)",
      name: "job_requirements_valid_source"
  end
end
