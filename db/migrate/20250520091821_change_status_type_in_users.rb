class ChangeStatusTypeInUsers < ActiveRecord::Migration[6.1]
  
  def up
    # 一旦、string の値を boolean に変換して更新するか、既存データを一律 true とするなどの処理を行います。
    change_column :users, :status, :boolean, default: true, using: 'CASE WHEN status = "true" THEN true ELSE false END'
  end

  def down
    change_column :users, :status, :string
  end
end
