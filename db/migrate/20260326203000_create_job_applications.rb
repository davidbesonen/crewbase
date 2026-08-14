class CreateJobApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :job_applications do |t|
      t.integer :job_id
      t.integer :profile_id
      t.integer :status, default: 0
      t.jsonb :question_answers, default: {}
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.datetime :withdrawn_at
      t.datetime :decision_at
      t.text :internal_notes
      t.integer :reviewed_by

      t.timestamps
    end

    add_index :job_applications, [ :job_id, :profile_id ], unique: true
  end
end
