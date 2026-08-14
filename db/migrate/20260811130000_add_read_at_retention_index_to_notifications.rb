class AddReadAtRetentionIndexToNotifications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :notifications,
      :read_at,
      name: "index_notifications_on_read_at_for_retention",
      where: "read_at IS NOT NULL",
      algorithm: :concurrently
  end
end
