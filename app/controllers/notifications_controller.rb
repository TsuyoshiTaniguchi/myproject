class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # 通知一覧（「全ての通知を見る」ページ）
  def index
    # 未読だけ
    # 自分の Comment/Like は除外
    # orphaned (ソースが消えた) 通知も除外
    raw = current_user.notifications
                 .unread
                 .where.not(
                   # source_type が Comment か Like かつ source_id が自分 → 除外
                   source_type: ["Comment","Like"],
                   source_id:   current_user.id
                 )
                 .order(created_at: :desc)
                 .to_a

    @notifications = raw
      .select(&:source)     # source が nil のレコードを全部削る
      .uniq { |n|
        [n.source_type, n.source_id, n.created_at.to_date]
      }
      .first(5)             # 重複排除後に最新 5 件だけ
  end

  # 通知をクリックして遷移するアクション
  def show
    n = current_user.notifications.find_by(id: params[:id])
    unless n
      return redirect_to notifications_path, alert: "通知が見つかりません"
    end

    n.update(read: true)
    redirect_to notification_redirect_path(n)
  end

  # PATCH /notifications/:id で既読にするなら show を呼び出すだけ
  def update
    show
  end

  # すべて既読にするボタン（マイページ／一覧ページ共通）
  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    redirect_to notifications_path, notice: "すべての通知が既読になりました。"
  end

  private

  # 通知ごとに飛ばす先を決める
  def notification_redirect_path(n)
    case n.notification_type
    when "comment"
      post_path(n.source.post)
    when "like"
      post_path(n.source.likeable)
    when "membership_request", "membership_approval", "membership_rejection"
      # 拒否通知の場合、Membership が物理削除されると n.source は nil になり得るため、
      # その場合はフォールバックとして groups_path (または適切なパス) を返す
      if n.source.present? && n.source.group.present?
        group_path(n.source.group)
      else
        groups_path
      end
    else
      root_path
    end
  end
end