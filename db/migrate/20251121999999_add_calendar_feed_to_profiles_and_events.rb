class AddCalendarFeedToProfilesAndEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :ical_feed_url, :string
    add_column :profiles, :ical_last_synced_at, :datetime

    add_column :calendar_events, :provider, :string
    add_column :calendar_events, :external_id, :string
    add_index :calendar_events, [ :profile_id, :provider, :external_id ], unique: true, name: "index_calendar_events_on_profile_provider_and_external_id"
  end
end
