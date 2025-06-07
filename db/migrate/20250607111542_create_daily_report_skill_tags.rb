class CreateDailyReportSkillTags < ActiveRecord::Migration[6.1]
  def change
    create_table :daily_report_skill_tags do |t|
      t.references :daily_report, null: false, foreign_key: true
      t.references :skill_tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
