class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.integer :role_id
      t.integer :user_id

      t.timestamps
    end
  end
end
