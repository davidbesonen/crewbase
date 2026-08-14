class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :email_notifications_enabled, null: false, default: true
      t.boolean :sms_notifications_enabled, null: false, default: false
      t.boolean :job_alert_notifications_enabled, null: false, default: true
      t.boolean :recommended_role_notifications_enabled, null: false, default: true
      t.boolean :upcoming_job_reminder_notifications_enabled, null: false, default: true
    end
  end
end
