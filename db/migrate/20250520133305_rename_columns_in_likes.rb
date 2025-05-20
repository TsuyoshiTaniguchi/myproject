class RenameColumnsInLikes < ActiveRecord::Migration[6.1]
  def change
    execute "PRAGMA foreign_keys = OFF"

    if column_exists?(:likes, :user_id_id)
      rename_column :likes, :user_id_id, :user_id
    end

    if column_exists?(:likes, :post_id_id)
      rename_column :likes, :post_id_id, :post_id
    end

    execute "PRAGMA foreign_keys = ON"
  end
end