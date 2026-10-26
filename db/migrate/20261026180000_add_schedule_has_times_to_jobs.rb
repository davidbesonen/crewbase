class AddScheduleHasTimesToJobs < ActiveRecord::Migration[8.0]
  def change
    # Preserve the meaning of existing timestamps; the posting form opts new
    # date-only schedules out of exact times explicitly.
    add_column :jobs, :schedule_has_times, :boolean, default: true, null: false
  end
end
