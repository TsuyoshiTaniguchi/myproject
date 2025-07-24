class AddConfirmableToAdmins < ActiveRecord::Migration[6.1]
  def change
    add_column :admins, :confirmed_at, :datetime
    add_column :admins, :confirmation_token, :string
    add_column :admins, :confirmation_sent_at, :datetime
    add_column :admins, :unconfirmed_email, :string

    add_index :admins, :confirmation_token, unique: true
  end
end