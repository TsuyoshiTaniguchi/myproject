class ChangeStatusToIntegerInUsers < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :status, :integer, using: 'status::integer', default: 0
  end
end