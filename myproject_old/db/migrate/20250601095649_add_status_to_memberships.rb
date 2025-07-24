class AddStatusToMemberships < ActiveRecord::Migration[6.1]
  def change
    add_column :memberships, :status, :string, default: "pending"
  end
end