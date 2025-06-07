class AddDetailsToActivityLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :activity_logs, :tech_stack, :string
    add_column :activity_logs, :deliverable_url, :string
  end
end
