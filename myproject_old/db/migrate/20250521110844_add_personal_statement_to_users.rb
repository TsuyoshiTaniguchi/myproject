class AddPersonalStatementToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :personal_statement, :string
  end
end
