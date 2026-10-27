class AddShowCountToProjectShows < ActiveRecord::Migration[8.1]
  def change
    add_column :project_shows, :show_count, :integer, default: 1, null: false
    add_check_constraint :project_shows, "show_count > 0 AND show_count <= 100", name: "project_shows_valid_show_count"
  end
end
