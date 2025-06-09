module Public
  class TasksController < ApplicationController
    before_action :set_daily_report

    def create
      @task = @daily_report.tasks.build(task_params)
      if @task.save
        redirect_back fallback_location: daily_report_path(@daily_report), notice: "タスクを追加しました。"
      else
        redirect_back fallback_location: daily_report_path(@daily_report), alert: "タスクの追加に失敗しました。"
      end
    end

    def update
      @task = @daily_report.tasks.find(params[:id])
      if @task.update(task_params)
        redirect_back fallback_location: daily_report_path(@daily_report), notice: "タスクを更新しました。"
      else
        redirect_back fallback_location: daily_report_path(@daily_report), alert: "タスクの更新に失敗しました。"
      end
    end

    def destroy
      @task = @daily_report.tasks.find(params[:id])
      @task.destroy
      redirect_back fallback_location: daily_report_path(@daily_report), notice: "タスクを削除しました。"
    end

    private

    def set_daily_report
      @daily_report = DailyReport.find(params[:daily_report_id])
    end

    def task_params
      params.require(:task).permit(:title, :completed)
    end
  end
end