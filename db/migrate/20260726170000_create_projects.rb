class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end

    add_index :projects, [ :company_id, :name ]
    add_reference :jobs, :project, foreign_key: true
  end
end
