class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # 公開済み or 自分のもの → show, compact
  before_action :find_public_daily_report, only: %i[show compact]
  # 自分のものだけ → edit, update, destroy
  before_action :find_owned_daily_report,  only: %i[edit update destroy]

  # GET /daily_reports
  def index
    @user ||= current_user
    base_reports = DailyReport.accessible_for(current_user, @user.id)
                              .order(date: :desc)
    filtered     = apply_filters(base_reports)

    @daily_reports = cacheable?(@user) ? cached_reports(filtered) : filtered

    respond_to do |format|
      format.html
      format.json { render json: @daily_reports }
    end
  end

  # GET /daily_reports/:id
  def show
    # @daily_report は find_public_daily_report で取得済み
    if @daily_report.user == current_user
      scope = @daily_report.user.daily_reports
    else
      scope = @daily_report.user.daily_reports.where(visibility: 'public_report')
    end
    @prev = scope.where('date < ?', @daily_report.date).order(date: :desc).first
    @next = scope.where('date > ?', @daily_report.date).order(date: :asc).first
    
  end

  # GET /daily_reports/new
  def new
    @daily_report = current_user.daily_reports.build
    if (last_report = current_user.daily_reports.order(date: :desc).first)
      # 未来の目標値と目標日数を前日から引き継ぐ
      @daily_report.future_goal_value = last_report.future_goal_value
      @daily_report.future_goal_days  = last_report.future_goal_days
    end  
  end

  # POST /daily_reports
  def create
    @daily_report             = current_user.daily_reports.build(daily_report_params)
    @daily_report.visibility  = "public_report"

    if @daily_report.save
      Rails.cache.delete("daily_report_ids/#{@user.id}")
      redirect_to daily_reports_path, notice: '日報が作成されました。'
    else
      flash.now[:alert] = '日報の作成に失敗しました。'
      render :new
    end
  end

  # GET /daily_reports/:id/edit
  def edit
    # @daily_report は find_owned_daily_report で取得済み
  end

  # PATCH/PUT /daily_reports/:id
  def update
    success = @daily_report.update(daily_report_params)
    Rails.cache.delete("daily_report_ids/#{current_user.id}") if success

    respond_to do |format|
      format.html do
        if success
          flash[:notice] = "更新が完了しました。"
          # ← return_to をホワイトリスト化して
          #    /daily_reports/:id 以外は無視し、show にフォールバック
          redirect_to safe_return_to || daily_report_path(@daily_report)
        else
          flash.now[:alert] = "更新に失敗しました。"
          render :edit
        end
      end
      format.js   # update.js.erb, toggle 用の JS レスポンスなどもそのまま動きます
    end
  end

  # DELETE /daily_reports/:id
  def destroy
    @daily_report.destroy
    Rails.cache.delete("daily_report_ids/#{@user.id}")
    redirect_to daily_reports_path, notice: '日報を削除しました。'
  end

  # GET /daily_reports/calendar_data.json
  def calendar_data
    # set_user で @user をセットしています
    events = @user.daily_reports.map do |r|
      {
        id:    r.id,
        title: r.location.presence || r.content.truncate(30),
        start: r.date.iso8601,
        # @user（表示しているページのユーザー）が current_user なら show、
        # それ以外のユーザーなら compact へ飛ばす
        url:   @user == current_user ?
                daily_report_path(r) :
                compact_daily_report_path(r)
      }
    end
  
    render json: events
  end
  
  

  # GET /daily_reports/performance_data.json
  def performance_data
    reports = current_user.daily_reports.order(:date)
    render json: {
      dates:       reports.map { |r| r.date.strftime('%Y-%m-%d') },
      performance: reports.map do |r|
        if r.task_achievement.present? && r.self_evaluation.present?
          ((r.task_achievement + r.self_evaluation) / 2.0).round(1)
        else
          nil
        end
      end
    }
  end

  # GET /daily_reports/future_growth_data.json
  def future_growth_data
    last_report = @user.daily_reports.order(:date).last
    today_val   = last_report&.task_achievement.to_i
    goal_val    = last_report&.future_goal_value.to_i
    days_ahead  = last_report&.future_goal_days.to_i

    if goal_val.positive? && days_ahead.positive?
      future_dates = (1..days_ahead).map { |i| (Date.today + i).strftime('%Y-%m-%d') }
      predicted_levels = future_dates.each_with_index.map do |_, idx|
        ratio = (idx + 1).to_f / days_ahead
        (today_val + (goal_val - today_val) * ratio).round(1)
      end
      render json: { future_dates: future_dates, predicted_levels: predicted_levels }
    else
      dates  = (1..5).map { |i| (Date.today + i).strftime('%Y-%m-%d') }
      levels = Array.new(dates.size, today_val)
      render json: { future_dates: dates, predicted_levels: levels }
    end
  end

  # GET /daily_reports/growth_data.json
  def growth_data
    reports = @user.daily_reports.order(:date)
    render json: {
      dates: reports.map { |r| r.date.strftime('%Y-%m-%d') },
      stats: reports.map { |r| r.task_achievement.to_i }
    }
  end

  # GET /daily_reports/:id/compact
  def compact
    # @daily_report, @user は find_public_daily_report でセット済み
  
    # 他人のレポートなら公開済みのみ、自分のなら全件をベースに
    scope = if @user == current_user
      @user.daily_reports
    else
      @user.daily_reports.where(visibility: 'public_report')
    end
  
    # 前後の日報（公開済or本人）のみを探す
    @prev = scope
              .where('date < ?', @daily_report.date)
              .order(date: :desc)
              .first
    @next = scope
              .where('date > ?', @daily_report.date)
              .order(date: :asc)
              .first
  end

  private

    # return_to が「/daily_reports/数字」のパスかだけを許可する
  def safe_return_to
    rt = params[:return_to].presence
    return rt if rt && rt.match?(/\A\/daily_reports\/\d+\z/)
    nil
  end

  # show/compact 用: 他人は公開済みのみ、自分は全件
  def find_public_daily_report
    @daily_report = DailyReport.find(params[:id])
    @user         = @daily_report.user

    unless @daily_report.user == current_user || @daily_report.public_report?
      redirect_to daily_reports_path, alert: 'この日報は公開されていません。'
    end
  end

  # edit/update/destroy 用: 自分のものだけ
  def find_owned_daily_report
    @daily_report = current_user.daily_reports.find(params[:id])
    @user         = current_user
  end

  # 既存ヘルパー類
  def apply_filters(relation)
    relation = relation.where('date >= ?', Date.today - params[:date_range].to_i.days) if params[:date_range].present?
    relation = relation.where('content LIKE ?', "%#{params[:keyword]}%")        if params[:keyword].present?
    relation
  end

  def cacheable?(user)
    !current_user.admin? && user == current_user && params.slice(:date_range, :keyword).empty?
  end

  def cached_reports(relation)
    cache_key = "daily_report_ids/#{@user.id}"
    ids = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      relation.limit(30).pluck(:id)
    end

    # Integerの配列にしてから改めてロード
    DailyReport.where(id: Array.wrap(ids)).order(date: :desc)
  end

  def set_user
    @user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :date, :location, :content,
      :task_achievement, :self_evaluation, :learning,
      :future_goal_value, :future_goal_days,
      :latitude, :longitude, :visibility
    )
  end
end