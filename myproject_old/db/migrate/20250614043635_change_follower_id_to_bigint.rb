class ChangeFollowerIdToBigint < ActiveRecord::Migration[6.1]
  def change
    change_column :connections, :follower_id, :bigint
    change_column :connections, :followed_id, :bigint
  end
end
