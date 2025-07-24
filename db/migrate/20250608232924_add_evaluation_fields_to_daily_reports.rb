class AddEvaluationFieldsToDailyReports < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_reports, :task_achievement, :integer
    add_column :daily_reports, :self_evaluation, :integer
    add_column :daily_reports, :learning, :text
  end
end
