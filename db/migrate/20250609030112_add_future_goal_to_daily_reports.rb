class AddFutureGoalToDailyReports < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_reports, :future_goal_value, :integer
    add_column :daily_reports, :future_goal_days, :integer
  end
end