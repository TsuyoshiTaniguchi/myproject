class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_daily_report, only: [:edit, :update, :destroy]

  def index
    # 通常は、自分自身の日報だけを表示
    @daily_reports = current_user.daily_reports.order(date: :desc)
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
