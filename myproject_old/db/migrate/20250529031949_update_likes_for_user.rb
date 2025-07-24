class UpdateLikesForUser < ActiveRecord::Migration[6.1]
  def up
    execute "UPDATE likes SET likeable_type = 'User' WHERE likeable_type IS NULL"
  end

  def down
    execute "UPDATE likes SET likeable_type = NULL WHERE likeable_type = 'User'"
  end
end