class CreateCreditsAndAddVisibilityToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :show_credits, :boolean, null: false, default: true

    create_table :credits do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :job, foreign_key: true
      t.references :project, foreign_key: true
      t.references :company, foreign_key: true
      t.string :role, null: false
      t.string :project_name, null: false
      t.string :company_name
      t.date :starts_on
      t.date :ends_on
      t.string :location
      t.text :description
      t.datetime :verified_at

      t.timestamps
    end

    add_index :credits, [ :profile_id, :starts_on ]
    add_index :credits, [ :profile_id, :job_id ],
      unique: true,
      where: "job_id IS NOT NULL"
  end
end
