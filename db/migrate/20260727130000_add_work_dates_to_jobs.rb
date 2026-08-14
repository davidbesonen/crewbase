class AddWorkDatesToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :work_dates, :date, array: true, default: [], null: false
  end
end
