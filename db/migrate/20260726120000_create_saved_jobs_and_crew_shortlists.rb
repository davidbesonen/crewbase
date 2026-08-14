class CreateSavedJobsAndCrewShortlists < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true
      t.timestamps
    end
    add_index :saved_jobs, [ :user_id, :job_id ], unique: true

    create_table :crew_shortlists do |t|
      t.references :company, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.timestamps
    end
    add_index :crew_shortlists, [ :company_id, :name ], unique: true

    create_table :crew_shortlist_memberships do |t|
      t.references :crew_shortlist, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.timestamps
    end
    add_index :crew_shortlist_memberships,
      [ :crew_shortlist_id, :profile_id ],
      unique: true,
      name: "index_crew_shortlist_memberships_on_list_and_profile"
  end
end
