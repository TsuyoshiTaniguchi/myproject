class AddReportedToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :reported, :boolean, default: false, null: false
  end
end