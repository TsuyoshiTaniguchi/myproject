class CreateConnections < ActiveRecord::Migration[6.1]
  def change
    create_table :connections do |t|
      t.integer :follower
      t.integer :followed

      t.timestamps
    end
  end
end
