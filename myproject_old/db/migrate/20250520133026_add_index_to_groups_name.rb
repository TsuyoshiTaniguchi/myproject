class AddIndexToGroupsName < ActiveRecord::Migration[6.1]
  def change
    add_index :groups, :name unless index_exists?(:groups, :name)
  end
end