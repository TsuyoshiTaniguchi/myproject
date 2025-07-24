class ChangeLikesToPolymorphic < ActiveRecord::Migration[6.1]
  def up
    rename_column :likes, :post_id, :likeable_id
    add_column :likes, :likeable_type, :string

    # 既存のデータを修正（すべて `Post` にする）
    execute "UPDATE likes SET likeable_type = 'Post' WHERE likeable_type IS NULL"

    # ここで `NOT NULL` 制約を追加
    change_column_null :likes, :likeable_type, false
  end

  def down
    remove_column :likes, :likeable_type
    rename_column :likes, :likeable_id, :post_id
  end
end