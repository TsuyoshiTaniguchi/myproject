class CreateAdminLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :admin_logs do |t|
      t.references :admin, null: false, foreign_key: true
      t.string :action
      t.integer :target_id
      t.string :target_type

      t.timestamps
    end
  end
end
