class AddDailyReportsPublicToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :daily_reports_public, :boolean
  end
end
