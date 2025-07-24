class AddLatitudeLongitudeToDailyReports < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:daily_reports, :latitude) 
      add_column :daily_reports, :latitude, :decimal, precision: 9, scale: 6
    end
    
    unless column_exists?(:daily_reports, :longitude)
      add_column :daily_reports, :longitude, :decimal, precision: 9, scale: 6
    end
  end
end
