class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type
      t.integer :source_id
      t.string :source_type
      t.datetime :read_at

      t.timestamps
    end
  end
end
