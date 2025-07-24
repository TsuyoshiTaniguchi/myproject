class AddStatusToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :status, :integer, default: 0, null: false  # `status` にデフォルト値を設定
  end
end