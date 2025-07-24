class ChangeStatusDefaultInUsers < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :status, 0
  end
end
