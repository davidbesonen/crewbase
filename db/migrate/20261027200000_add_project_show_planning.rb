class AddProjectShowPlanning < ActiveRecord::Migration[8.1]
  def change
    create_table :project_shows do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :city, null: false
      t.string :state
      t.string :country
      t.string :venue_name
      t.date :starts_on, null: false
      t.date :ends_on
      t.timestamps
    end
    add_index :project_shows, [ :project_id, :starts_on ]
    add_column :jobs, :show_coverage, :integer, null: false, default: 0
    create_table :job_shows do |t|
      t.references :job, null: false, foreign_key: true
      t.references :project_show, null: false, foreign_key: true
      t.timestamps
    end
    add_index :job_shows, [ :job_id, :project_show_id ], unique: true
    add_column :job_offers, :work_dates, :date, array: true, default: [], null: false
  end
end
