module Public
  class TasksController < ApplicationController
    before_action :authenticate_user!
    before_action :set_daily_report
    before_action :set_task, only: %i[update destroy]

    # HTML と JS 両方受け入れ
    # → 暗黙ビュー（create.js.erb など）を使わず、常に replace_tasks.js.erb を返す
    %i[create update destroy bulk_create].each do |action|
      define_method(action) do
        case action
        when :create
          @daily_report.tasks.create(task_params)
        when :update
          @task.update(task_params)
        when :destroy
          @task.destroy
        when :bulk_create
          titles = params[:titles].to_s.lines.map(&:strip).reject(&:blank?)
          titles.each { |t| @daily_report.tasks.create(title: t) }
        end

        respond_to do |format|
          format.html { redirect_to daily_report_path(@daily_report) }
          format.js   { render 'public/tasks/replace_tasks' }
        end
      end
    end

    private

    def set_daily_report
      @daily_report = current_user.daily_reports.find(params[:daily_report_id])
    end

    def set_task
      @task = @daily_report.tasks.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:title, :completed)
    end
  end
end