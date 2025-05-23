class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum role: { member: "member", admin: "admin" }  # `admin` / `member` の役割を管理
end