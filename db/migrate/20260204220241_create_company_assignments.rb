class CreateCompanyAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :company_assignments do |t|
      t.string :role
      t.integer :user_id
      t.integer :profile_id
      t.integer :company_id

      t.timestamps
    end

    add_index :company_assignments, [ :company_id, :user_id ], unique: true
    add_index :company_assignments, [ :company_id, :profile_id ], unique: true
  end
end
