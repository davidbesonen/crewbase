class CreateCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_events do |t|
      t.string :event_type
      t.integer :profile_id
      t.string :name
      t.datetime :from_date
      t.datetime :to_date

      t.timestamps
    end
  end
end
