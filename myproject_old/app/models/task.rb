class Task < ApplicationRecord
  belongs_to :daily_report

  validates :title, presence: true

end
