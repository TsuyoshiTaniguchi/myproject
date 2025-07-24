class AddVisibilityToDailyReports < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_reports, :visibility, :integer, default: 1 #  修正: `default: 1` を正しく記述
  end
end