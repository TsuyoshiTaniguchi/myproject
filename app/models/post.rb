class Post < ApplicationRecord
  belongs_to :user


  validates :title, presence: true
  validates :content, presence: true
end


<%= link_to "削除", post_path(@post), method: :delete, data: { confirm: "本当に削除しますか？" } %>