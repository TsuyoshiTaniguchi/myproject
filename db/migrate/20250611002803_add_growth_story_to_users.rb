class AddGrowthStoryToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :growth_story, :text
  end
end
