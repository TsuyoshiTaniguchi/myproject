class ChangeFollowerIdTypeInConnections < ActiveRecord::Migration[6.1]
  def change
    change_column :connections, :follower_id, :bigint
  end
end