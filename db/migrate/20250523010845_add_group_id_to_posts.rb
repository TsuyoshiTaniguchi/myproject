class AddGroupIdToPosts < ActiveRecord::Migration[6.1]
  def change
    change_column :posts, :group_id, :bigint
    add_foreign_key :posts, :groups
  end
end
