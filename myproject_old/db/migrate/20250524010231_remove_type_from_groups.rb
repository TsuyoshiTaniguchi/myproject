class RemoveTypeFromGroups < ActiveRecord::Migration[6.1]
  def change
    remove_column :groups, :type, :string
  end
end