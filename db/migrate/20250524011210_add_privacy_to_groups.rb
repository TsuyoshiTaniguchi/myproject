class AddPrivacyToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :privacy, :string, default: "public"  # デフォルト値を設定！
  end
end