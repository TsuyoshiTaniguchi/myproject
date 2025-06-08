class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_daily_report, only: [:edit, :update, :destroy]

  def index
    # ユーザーIDが指定されていればそのユーザー、なければログインユーザー
    @user = params[:user_id] ? User.find_by(id: params[:user_id]) : current_user

    # 管理者の場合は全件表示、一般ユーザーの場合は自分の public 日報のみ表示
    if current_user.admin? || current_user == @user
      reports_scope = ::DailyReport.where(user_id: @user.id)
    else
      reports_scope = ::DailyReport.where(user_id: @user.id, visibility: :public_report)
    end

    # 日付で降順にソート
    reports_scope = reports_scope.order(date: :desc)

    # 期間フィルタ：params[:date_range] に指定された日数分だけさかのぼる
    if params[:date_range].present?
      date_range = Date.today - params[:date_range].to_i.days
      reports_scope = reports_scope.where("date >= ?", date_range)
    end

    # キーワード検索：params[:keyword] があれば、content にその文字列が含まれる日報を抽出
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      reports_scope = reports_scope.where("content LIKE ?", keyword)
    end

    # フィルタや検索条件がない場合（一般ユーザーの場合のみ）に limit とキャッシュを適用
    if current_user.admin? || params[:date_range].present? || params[:keyword].present?
      @daily_reports = reports_scope
    else
      reports_scope = reports_scope.limit(30)
      cache_key = "daily_reports/#{@user.id}"
      @daily_reports = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        reports_scope.to_a
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: @daily_reports }
    end
  end

  def new
    @daily_report = current_user.daily_reports.build
  end

  def create
    @daily_report = current_user.daily_reports.build(daily_report_params)
    if @daily_report.save
      redirect_to daily_reports_path, notice: '日報が作成されました。'
    else
      flash.now[:alert] = '日報の作成に失敗しました。'
      render :new
    end
  end

  def edit
    # @daily_report は set_daily_report で取得済み
  end

  def show
    @daily_report = ::DailyReport.find(params[:id])
    # 必要なら現在のユーザーによるアクセス制限も実装する
  end

  def update
    if @daily_report.update(daily_report_params)
      redirect_to daily_reports_path, notice: '日報が更新されました。'
    else
      flash.now[:alert] = '更新に失敗しました。'
      render :edit
    end
  end

  def destroy
    @daily_report = ::DailyReport.find(params[:id])
    # 関連する daily_report_skill_tags のレコードを先に削除してから、日報自体を削除
    @daily_report.daily_report_skill_tags.destroy_all
    @daily_report.destroy
    redirect_to daily_reports_path, notice: "日報を削除しました。"
  end

  def calendar_data
    reports = ::DailyReport.where(user: current_user).map do |r|
      {
        id: r.id,
        title: r.location.present? ? r.location : r.content.truncate(30),
        date: r.date&.iso8601,
        content: r.content,
        visibility: r.visibility,
        skill_tags: r.skill_tags.pluck(:name),
        importance_level: r.importance_level || 1
      }
    end
    render json: reports
  end

  # 成長データ (日付と、コンテンツ文字数＋タグ数 の推移を返す例)
  def growth_data
    # ユーザーの日付順にタスク達成度の配列を生成
    reports = DailyReport.order(:date)
    render json: {
      dates: reports.map { |r| r.date.strftime("%Y-%m-%d") },
      stats: reports.map { |r| r.task_achievement || 0 }
    }
  end

  # 未来の成長予測用の JSON アクション
  def future_growth_data
    render json: {
      future_dates: ["2025-06-10", "2025-06-11", "2025-06-12"],
      predicted_levels: [7, 9, 10]
    }
  end


  private

  # 指定された日報を、管理者なら全体、一般ユーザーなら自分のものから取得する
  def set_daily_report
    @daily_report = if current_user.admin?
                      ::DailyReport.find_by(id: params[:id])
                    else
                      current_user.daily_reports.find_by(id: params[:id])
                    end
    unless @daily_report
      redirect_to daily_reports_path, alert: "指定された日報が見つかりませんでした。"
    end
  end

  def daily_report_params
    params.require(:daily_report).permit(:date, :location, :content)
  end
end
