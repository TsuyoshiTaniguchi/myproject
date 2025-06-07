class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_daily_report, only: [:edit, :update, :destroy]

  def index
    @user = params[:user_id] ? User.find_by(id: params[:user_id]) : current_user
  
    # 期間フィルタ（過去〇日間のデータ）
    date_range = params[:date_range].present? ? Date.today - params[:date_range].to_i.days : nil
  
    # キーワード検索（例：「Rails」などを含む日報を取得）
    keyword = params[:keyword].present? ? "%#{params[:keyword]}%" : nil
  
    @daily_reports = @user.daily_reports.order(date: :desc)
    
    @daily_reports = @daily_reports.where("date >= ?", date_range) if date_range
    @daily_reports = @daily_reports.where("content LIKE ?", keyword) if keyword
    @daily_reports = DailyReport.where(user_id: params[:user_id]).order(date: :desc).limit(30)
    cache_key = "daily_reports/#{params[:user_id]}"
    @daily_reports = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      DailyReport.where(user_id: params[:user_id]).order(date: :desc).limit(30).to_a
    end

    @daily_reports = DailyReport.where(user_id: params[:user_id]).order(date: :desc).limit(30)

    respond_to do |format|
      format.html
      format.json { render json: @daily_reports }
    end
  end

  def index
    @user = params[:user_id] ? User.find_by(id: params[:user_id]) : current_user
  
    # 管理者はすべての日報を閲覧可能
    @daily_reports = if current_user.admin?
                       DailyReport.order(date: :desc)
                     else
                       DailyReport.where(user_id: @user.id).where(visibility: :public).order(date: :desc)
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

  def update
    if @daily_report.update(daily_report_params)
      redirect_to daily_reports_path, notice: '日報が更新されました。'
    else
      flash.now[:alert] = '更新に失敗しました。'
      render :edit
    end
  end

  def destroy
    @daily_report.destroy
    redirect_to daily_reports_path, notice: '日報が削除されました。'
  end

  private

  # セット時に、管理者の場合は全 DailyReport から、
  # 一般ユーザーの場合は current_user に紐づく日報のみ検索する
  def set_daily_report
    @daily_report = if current_user.admin?
                      DailyReport.find_by(id: params[:id])
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
