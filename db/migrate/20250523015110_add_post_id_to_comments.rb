class AddPostIdToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :post_id, :integer
    add_foreign_key :comments, :posts
    add_index :comments, :post_id
  end
end