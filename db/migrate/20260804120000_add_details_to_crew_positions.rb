class AddDetailsToCrewPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :crew_positions, :description, :text
    add_column :crew_positions, :pay_min, :float
    add_column :crew_positions, :pay_max, :float
    add_column :crew_positions, :pay_period, :integer
  end
end
