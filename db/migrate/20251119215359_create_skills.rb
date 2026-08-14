class CreateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills do |t|
      t.string :name
      t.integer :industry_id
      t.integer :occupation_id

      t.timestamps
    end
  end
end
