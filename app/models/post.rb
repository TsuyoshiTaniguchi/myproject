class Post < ApplicationRecord
  belongs_to :user

  scope :active_users_posts, -> { joins(:user).where(users: { status: "active" }) }

  validates :title, presence: true
  validates :content, presence: true, length: { minimum: 10 }
  
end

