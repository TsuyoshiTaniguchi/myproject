class AddPortfolioFileToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :portfolio_file, :string
  end
end
