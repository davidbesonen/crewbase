class AddIcalSyncStatusToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :ical_sync_attempted_at, :datetime
    add_column :profiles, :ical_sync_error, :text
  end
end
