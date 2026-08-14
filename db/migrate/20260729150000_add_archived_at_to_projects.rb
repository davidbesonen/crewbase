class AddArchivedAtToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :archived_at, :datetime
    add_index :projects, [ :company_id, :archived_at ]
  end
end
