class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  scope :active, -> { where(status: "active") }

  has_many :posts, dependent: :destroy

  def active_for_authentication?
    super && (status == "active")
  end

  
  def withdraw!
    update(status: "withdrawn")
  end
       
end
