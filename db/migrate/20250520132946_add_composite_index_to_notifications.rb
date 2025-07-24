class AddCompositeIndexToNotifications < ActiveRecord::Migration[6.1]
  def change
    # source_type と source_id の複合インデックスを追加
    add_index :notifications, [:source_type, :source_id], name: "index_notifications_on_source"
  end
end