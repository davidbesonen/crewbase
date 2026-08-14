class AddVisibleToCredits < ActiveRecord::Migration[8.0]
  def change
    add_column :credits, :visible, :boolean, default: true, null: false
    add_index :credits, [ :profile_id, :visible ]
  end
end
