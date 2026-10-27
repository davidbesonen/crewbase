class AddProjectTypeToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :project_type, :integer, null: false, default: 0
  end
end
