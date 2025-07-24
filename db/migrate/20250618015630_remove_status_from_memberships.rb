class RemoveStatusFromMemberships < ActiveRecord::Migration[6.1]
  def change
    remove_column :memberships, :status, :string
  end
end
