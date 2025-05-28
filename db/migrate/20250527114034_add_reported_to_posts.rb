class AddReportedToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :reported, :boolean, default: false  # デフォルトは `false`
  end
end
