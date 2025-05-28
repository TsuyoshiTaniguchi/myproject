class AddReportedToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :reported, :boolean, default: false, null: false
  end
end