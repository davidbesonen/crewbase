class CreateTrustAndSafety < ActiveRecord::Migration[8.1]
  def change
    create_table :user_blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :user_blocks, [ :blocker_id, :blocked_user_id ], unique: true
    add_check_constraint :user_blocks, "blocker_id <> blocked_user_id", name: "user_blocks_different_users"
    create_table :safety_reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true, null: false
      t.string :subject_label, null: false
      t.string :category, null: false
      t.text :details, null: false
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_index :safety_reports, [ :status, :created_at ]
    create_table :moderation_decisions do |t|
      t.references :safety_report, null: false, foreign_key: true
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.string :previous_status, null: false
      t.string :status, null: false
      t.text :notes, null: false
      t.timestamps
    end
  end
end
