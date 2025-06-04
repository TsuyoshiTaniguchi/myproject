class CreateDailyReports < ActiveRecord::Migration[6.1]
  def change
    create_table :daily_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.string :location
      t.text :content

      t.timestamps
    end
  end
end