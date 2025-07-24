class AddRecipientToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :recipient_id, :integer
    add_index :notifications, :recipient_id
  end
end