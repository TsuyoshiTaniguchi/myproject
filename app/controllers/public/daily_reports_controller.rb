class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_daily_report, only: %i[show edit update destroy]

  # GET /daily_reports
  def index
    @user ||= current_user
    base_reports = DailyReport.accessible_for(current_user, @user.id).order(date: :desc)
    filtered     = apply_filters(base_reports)
  
    @daily_reports = cacheable?(@user) ? cached_reports(filtered) : filtered
  
    respond_to do |format|
      format.html
      format.json { render json: @daily_reports }
    end
  end
  

  # GET /daily_reports/:id
  def show
    # @daily_report は set_daily_report で取得済み
  end

  def new
    @daily_report = current_user.daily_reports.build
  end

  def create
    @daily_report = current_user.daily_reports.build(daily_report_params)
    @daily_report.visibility = "public_report"  # 公開設定
  
    if @daily_report.save
      Rails.cache.delete("daily_reports/#{@user.id}")
      redirect_to daily_reports_path, notice: '日報が作成されました。'
    else
      flash.now[:alert] = '日報の作成に失敗しました。'
      render :new
    end
  end

  # GET /daily_reports/:id/edit
  def edit; end

  # PATCH/PUT /daily_reports/:id
  def update
    @daily_report = current_user.daily_reports.find(params[:id])
    if @daily_report.update(daily_report_params)
      Rails.cache.delete("daily_reports/#{current_user.id}")
      flash[:notice] = "公開設定が更新されました。"
      redirect_to daily_reports_path
    else
      flash.now[:alert] = "更新に失敗しました。"
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

    unless goal_val.positive? && days_ahead.positive?
      dates  = (1..5).map { |i| (Date.today + i).strftime('%Y-%m-%d') }
      levels = Array.new(dates.size, today_val)
      return render json: { future_dates: dates, predicted_levels: levels }
    end

    future_dates = (1..days_ahead).map { |i| (Date.today + i).strftime('%Y-%m-%d') }
    predicted_levels = future_dates.each_with_index.map do |_, idx|
      ratio = (idx + 1).to_f / days_ahead
      (today_val + (goal_val - today_val) * ratio).round(1)
    end

    render json: { future_dates: future_dates, predicted_levels: predicted_levels }
  end

  # GET /daily_reports/growth_data.json
  def growth_data
    reports = @user.daily_reports.order(:date)
    render json: {
      dates: reports.map { |r| r.date.strftime('%Y-%m-%d') },
      stats: reports.map { |r| r.task_achievement.to_i }
    }
  end

  private

  def apply_filters(relation)
    relation = relation.where('date >= ?', Date.today - params[:date_range].to_i.days) if params[:date_range].present?
    relation = relation.where('content LIKE ?', "%#{params[:keyword]}%")        if params[:keyword].present?
    relation
  end
  
  def cacheable?(user)
    !current_user.admin? && user == current_user && params.slice(:date_range, :keyword).empty?
  end
  
  def cached_reports(relation)
    Rails.cache.fetch("daily_reports/#{@user.id}", expires_in: 24.hours) do
      relation.limit(30).to_a
    end
  end

  def set_user
    @user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
  end

  def set_daily_report
    @daily_report = DailyReport
                      .accessible_for(current_user, @user.id)
                      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to daily_reports_path, alert: '日報が見つかりませんでした。'
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