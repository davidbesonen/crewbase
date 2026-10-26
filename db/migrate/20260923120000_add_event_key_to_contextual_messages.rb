class AddEventKeyToContextualMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :contextual_messages, :event_key, :string
    add_index :contextual_messages, [ :conversation_id, :event_key ], unique: true
  end
end
