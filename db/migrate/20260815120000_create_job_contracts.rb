class CreateJobContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :job_contracts do |t|
      t.references :job, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false

      t.timestamps
    end
  end
end
