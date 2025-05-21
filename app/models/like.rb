class Like < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :post

  # バリデーション
  validates :user_id, uniqueness: { scope: :post_id } # 同じ投稿に対してユーザーは1回しか「いいね」できない

  # スコープ（特定の投稿の「いいね」一覧を取得）
  scope :by_post, ->(post_id) { where(post_id: post_id) }

  # いいねを解除するメソッド
  def unlike!
    destroy
  end
end