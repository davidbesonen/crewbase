class AddAdminManagement < ActiveRecord::Migration[8.1]
  def change
    %i[users companies jobs].each do |table|
      add_column table, :restricted_at, :datetime
      add_index table, :restricted_at
    end
    create_table :admin_audit_events do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true, null: false
      t.string :action, null: false
      t.text :reason, null: false
      t.jsonb :changeset, null: false, default: {}
      t.timestamps
    end
    add_index :admin_audit_events, :created_at
  end
end
