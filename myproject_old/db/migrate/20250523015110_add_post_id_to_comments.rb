class AddPostIdToComments < ActiveRecord::Migration[6.1]
  def change
    change_column :comments, :post_id, :bigint
    add_foreign_key :comments, :posts
  end
end
