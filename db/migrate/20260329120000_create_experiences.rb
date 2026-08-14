class CreateExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :experiences do |t|
      t.integer :profile_id, null: false
      t.string :title, null: false
      t.string :company_name, null: false
      t.integer :company_id
      t.string :start_month
      t.string :start_year
      t.string :end_month
      t.string :end_year
      t.boolean :currently_active, null: false, default: false
      t.text :summary

      t.timestamps
    end

    add_index :experiences, :profile_id
  end
end
