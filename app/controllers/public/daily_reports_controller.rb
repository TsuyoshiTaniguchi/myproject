class Public::DailyReportsController < ApplicationController
  before_action :authenticate_user!  # ユーザー認証（Devise等利用の場合）
  before_action :set_daily_report, only: [:edit, :update, :destroy]

  def index
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
      render :new
    end
  end

  def edit
    @daily_report = current_user.daily_reports.find(params[:id])
  end

  def update
    @daily_report = current_user.daily_reports.find(params[:id])
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

  def set_daily_report
    @daily_report = current_user.daily_reports.find_by(id: params[:id])
    unless @daily_report
      redirect_to daily_reports_path, alert: "指定された日報が見つかりませんでした。"
    end
  end

  def daily_report_params
    params.require(:daily_report).permit(:date, :location, :content)
  end
end
