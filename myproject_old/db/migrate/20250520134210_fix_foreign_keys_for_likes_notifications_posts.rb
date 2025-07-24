class FixForeignKeysForLikesNotificationsPosts < ActiveRecord::Migration[6.1]
  def change
    # likes テーブル
    begin
      remove_foreign_key :likes, column: :user_id
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn "likes: Could not remove foreign key on user_id: #{e.message}"
    end
    begin
      remove_foreign_key :likes, column: :post_id
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn "likes: Could not remove foreign key on post_id: #{e.message}"
    end
    add_foreign_key :likes, :users, column: :user_id
    add_foreign_key :likes, :posts, column: :post_id

    # notifications テーブル
    begin
      remove_foreign_key :notifications, column: :user_id
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn "notifications: Could not remove foreign key on user_id: #{e.message}"
    end
    add_foreign_key :notifications, :users, column: :user_id

    # posts テーブル
    begin
      remove_foreign_key :posts, column: :user_id
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn "posts: Could not remove foreign key on user_id: #{e.message}"
    end
    add_foreign_key :posts, :users, column: :user_id
  end
end