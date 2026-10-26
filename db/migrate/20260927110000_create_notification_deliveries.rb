class CreateNotificationDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_deliveries do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.string :deduplication_key, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :payload, null: false, default: {}
      t.datetime :attempted_at
      t.datetime :sent_at
      t.string :failure_class
      t.timestamps
    end
    add_index :notification_deliveries, :deduplication_key, unique: true
    add_index :notification_deliveries, [ :status, :created_at ]
  end
end
