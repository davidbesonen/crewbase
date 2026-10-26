class CreateCrewNetwork < ActiveRecord::Migration[8.0]
  def change
    create_table :network_connections do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.text :introduction
      t.datetime :responded_at
      t.timestamps
    end
    add_check_constraint :network_connections, "sender_id <> recipient_id", name: "network_connections_distinct_users"
    add_index :network_connections, "LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id)", unique: true, name: "network_connections_unique_pair"

    create_table :network_job_shares do |t|
      t.references :job, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.text :note
      t.timestamps
    end
    add_index :network_job_shares, [ :job_id, :sender_id, :recipient_id ], unique: true, name: "network_job_shares_unique_recipient"
    add_check_constraint :network_job_shares, "sender_id <> recipient_id", name: "network_job_shares_distinct_users"
  end
end
