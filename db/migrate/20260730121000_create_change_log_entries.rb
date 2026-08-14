class CreateChangeLogEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :change_log_entries do |t|
      t.string :title, null: false
      t.text :summary, null: false
      t.datetime :published_at
      t.timestamps
    end

    add_index :change_log_entries, :published_at
  end
end
