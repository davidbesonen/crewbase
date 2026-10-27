class AddShowTimeToProjectShows < ActiveRecord::Migration[8.1]
  def change
    add_column :project_shows, :show_time, :time
  end
end
