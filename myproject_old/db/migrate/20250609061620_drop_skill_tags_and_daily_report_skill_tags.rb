class DropSkillTagsAndDailyReportSkillTags < ActiveRecord::Migration[6.1]
  def change
    def up
      # それぞれのテーブルが存在するか条件をつけると安全
      drop_table :daily_report_skill_tags, if_exists: true
      drop_table :skill_tags, if_exists: true
    end
  
    def down
      # 元に戻す場合は必要な定義を記載する（または raise する）
      raise ActiveRecord::IrreversibleMigration
    end
  
  end
end
