class Notification < ApplicationRecord

  belongs_to :user
  belongs_to :source, polymorphic: true #  `notifiable` ではなく `source` に統一！

  validates :notification_type, presence: true

end