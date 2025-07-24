class ChangeNotificationTypeToInteger < ActiveRecord::Migration[6.1]
  def change
    change_column :notifications, :notification_type, :integer, using: 'notification_type::integer'
  end
end