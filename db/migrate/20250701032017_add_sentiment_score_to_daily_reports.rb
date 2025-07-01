class AddSentimentScoreToDailyReports < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_reports, :sentiment_score, :decimal, precision: 4, scale: 3
  end

end
