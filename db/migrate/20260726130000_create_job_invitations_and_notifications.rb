class CreateJobInvitationsAndNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :job_invitations do |t|
      t.references :job, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :responded_at
      t.timestamps
    end
    add_index :job_invitations, [ :job_id, :profile_id ], unique: true

    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true
      t.string :kind, null: false
      t.text :message, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, [ :recipient_id, :read_at ]
  end
end
