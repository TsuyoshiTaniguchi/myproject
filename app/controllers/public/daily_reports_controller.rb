class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_daily_report, only: [:show, :edit, :update, :destroy]

  # GET /daily_reports
  def index
    # 管理者または対象ユーザー自身であれば、全件取得
    if current_user.admin? || current_user == @user
      reports = ::DailyReport.where(user: @user)
    else
      # 一般ユーザーの場合は、公開のみ取得
      reports = ::DailyReport.where(user: @user, visibility: ::DailyReport.visibilities[:public_report])
    end
  
    reports = reports.order(date: :desc)
  
    # 期間フィルタ
    if params[:date_range].present?
      start_date = Date.today - params[:date_range].to_i.days
      reports = reports.where("date >= ?", start_date)
    end
  
    # キーワード検索
    if params[:keyword].present?
      reports = reports.where("content LIKE ?", "%#{params[:keyword]}%")
    end
  
    # 一般ユーザーかつフィルタ無しの場合はキャッシュ利用（24時間有効）
    if !current_user.admin? && params.slice(:date_range, :keyword).empty?
      cache_key = "daily_reports/#{@user.id}"
      @daily_reports = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        reports.limit(30).to_a
      end
    else
      @daily_reports = reports
    end
  
    respond_to do |format|
      format.html
      format.json { render json: @daily_reports }
    end
  end

  # GET /daily_reports/:id
  def show
    # @daily_report は set_daily_report で取得済み
  end

  # GET /daily_reports/new
  def new
    @daily_report = current_user.daily_reports.build
  end

  # POST /daily_reports
  def create
    @daily_report = current_user.daily_reports.build(daily_report_params)

    if @daily_report.save
      Rails.cache.delete("daily_reports/#{@user.id}")
      redirect_to daily_reports_path, notice: '日報が作成されました。'
    else
      flash.now[:alert] = '日報の作成に失敗しました。'
      render :new
    end
  end

  # GET /daily_reports/:id/edit
  def edit
  end

  # PATCH/PUT /daily_reports/:id
  def update
    if @daily_report.update(daily_report_params)
      Rails.cache.delete("daily_reports/#{@user.id}")
      redirect_to daily_reports_path, notice: '日報が更新されました。'
    else
      flash.now[:alert] = '更新に失敗しました。'
      render :edit
    end
  end

  # DELETE /daily_reports/:id
  def destroy
    @daily_report.destroy
    Rails.cache.delete("daily_reports/#{@user.id}")
    redirect_to daily_reports_path, notice: '日報を削除しました。'
  end

  # GET /daily_reports/calendar_data.json
  def calendar_data
    # set_user により @user が設定されているので、そちらを利用
    events = @user.daily_reports.map do |r|
      {
        id:    r.id,
        title: r.location.presence || r.content.truncate(30),
        start: r.date.iso8601,
        url:   daily_report_path(r)
      }
    end
    render json: events
  end

  # GET /daily_reports/performance_data.json
  def performance_data
    reports = @user.daily_reports.order(:date)
    render json: {
      dates:             reports.map { |r| r.date.strftime('%Y-%m-%d') },
      task_achievements: reports.map { |r| r.task_achievement.to_i },
      self_evaluations:  reports.map { |r| r.self_evaluation.to_i }
    }
  end

  # GET /daily_reports/future_growth_data.json
  def future_growth_data
    last_report = @user.daily_reports.order(:date).last
    today_val   = last_report&.task_achievement.to_i
    goal_val    = last_report&.future_goal_value.to_i
    days_ahead  = last_report&.future_goal_days.to_i  # 何日先の目標か

    unless goal_val.positive? && days_ahead.positive?
      dates  = (1..5).map { |i| (Date.today + i).strftime("%Y-%m-%d") }
      levels = Array.new(dates.size, today_val)
      return render json: { future_dates: dates, predicted_levels: levels }
    end

    future_dates = (1..days_ahead).map { |i| (Date.today + i).strftime("%Y-%m-%d") }
    predicted_levels = future_dates.each_with_index.map do |_, idx|
      ratio = (idx + 1).to_f / days_ahead
      (today_val + (goal_val - today_val) * ratio).round(1)
    end

    render json: { future_dates: future_dates, predicted_levels: predicted_levels }
  end

  def growth_data
    reports = @user.daily_reports.order(:date)
    render json: {
      dates: reports.map { |r| r.date.strftime('%Y-%m-%d') },
      stats: reports.map { |r| r.task_achievement.to_i } # または適切なパフォーマンス数値
    }
  end
  

  private

  def set_user
    @user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
  end

  def set_daily_report
    scope = current_user.admin? ? DailyReport.all : current_user.daily_reports
    @daily_report = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to daily_reports_path, alert: '日報が見つかりませんでした。'
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :date, :location, :content,
      :task_achievement, :self_evaluation, :learning,
      :latitude, :longitude
    )
  end
end