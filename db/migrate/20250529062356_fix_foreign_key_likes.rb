class FixForeignKeyLikes < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :likes, :users, column: :likeable_id
    add_foreign_key :likes, :posts, column: :likeable_id
  end
end