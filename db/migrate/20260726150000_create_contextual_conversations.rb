class CreateContextualConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :context, polymorphic: true, null: false
      t.timestamps
    end
    add_index :conversations, [ :context_type, :context_id ], unique: true

    create_table :conversation_memberships do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at
      t.timestamps
    end
    add_index :conversation_memberships, [ :conversation_id, :user_id ], unique: true

    create_table :contextual_messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end
  end
end
