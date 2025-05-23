class ChangeGroupIdDefaultInPosts < ActiveRecord::Migration[6.1]
  def change
    change_column :posts, :group_id, :integer, null: true
  end
end