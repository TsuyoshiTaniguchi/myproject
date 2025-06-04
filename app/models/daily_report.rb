class DailyReport < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :location, presence: true
  validates :content, presence: true

end
