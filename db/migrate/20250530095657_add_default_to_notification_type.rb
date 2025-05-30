class AddDefaultToNotificationType < ActiveRecord::Migration[6.1]
  def change
    change_column_default :notifications, :notification_type, 0
  end
end