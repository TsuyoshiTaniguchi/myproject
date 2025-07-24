class AddDefaultToLikesUserId < ActiveRecord::Migration[6.1]
  def change
    change_column_default :likes, :user_id, 1  # 仮のデフォルトユーザーID（適宜修正）
  end
end