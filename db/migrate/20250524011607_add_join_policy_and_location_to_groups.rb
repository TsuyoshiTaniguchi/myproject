class AddJoinPolicyAndLocationToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :join_policy, :string, default: "open"
    add_column :groups, :location, :string
  end
end