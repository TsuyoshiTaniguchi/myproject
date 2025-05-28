class AddPortfolioUrlToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :portfolio_url, :string
  end
end
