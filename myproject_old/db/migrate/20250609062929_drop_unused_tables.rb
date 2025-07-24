class DropUnusedTables < ActiveRecord::Migration[6.1]
  def up
    # 依存関係のあるテーブルから削除
    drop_table :project_tags, if_exists: true
    drop_table :activity_logs, if_exists: true
    drop_table :daily_report_skill_tags, if_exists: true

    # 次に、それに依存されるテーブルを削除
    drop_table :skill_tags, if_exists: true
    drop_table :projects, if_exists: true
    drop_table :tags, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Dropped tables cannot be restored."
  end
end