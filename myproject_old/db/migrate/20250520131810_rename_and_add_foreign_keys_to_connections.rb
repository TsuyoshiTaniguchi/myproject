class RenameAndAddForeignKeysToConnections < ActiveRecord::Migration[6.1]
  def change
    # カラムのリネーム（条件付きで実施）
    if column_exists?(:connections, :follower)
      rename_column :connections, :follower, :follower_id
    end

    if column_exists?(:connections, :followed)
      rename_column :connections, :followed, :followed_id
    end

    # インデックス追加
    add_index :connections, :follower_id unless index_exists?(:connections, :follower_id)
    add_index :connections, :followed_id unless index_exists?(:connections, :followed_id)

    # 外部キーの追加（users テーブルへの参照）
    add_foreign_key :connections, :users, column: :follower_id
    add_foreign_key :connections, :users, column: :followed_id
  end
end