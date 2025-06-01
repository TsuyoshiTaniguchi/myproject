class AddReportedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :reported, :boolean, default: false
  end
end