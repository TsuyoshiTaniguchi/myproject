class AddCommitHashToActivityLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :activity_logs, :commit_hash, :string
  end
end
