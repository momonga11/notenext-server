# frozen_string_literal: true

# タスク情報を管理するクラス
class V1::TasksController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:project_id])
  }
  before_action :set_note, only: %i[create update destroy]
  before_action :set_task, only: %i[update destroy]

  # POST /tasks
  def create
    @task = @note.build_task(task_params)

    if @task.save
      response_created_request(@task, v1_project_url(@task))
    else
      response_unprocessable_entity(@task)
    end
  end

  # PATCH/PUT /tasks/1
  def update
    has_lock_version!(params, :task)

    if @task.update(task_params)
      response_success_request(@task)
    else
      response_unprocessable_entity(@task)
    end
  end

  # DELETE /tasks/1
  def destroy
    if @task.destroy
      response_success_request
    else
      response_unprocessable_entity(@task)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def task_params
    param_url_pass = params.permit(:project_id, :note_id)

    # noteに値がない場合にはURLパラメータを返す
    return param_url_pass if params.key?(:task) && !params[:task].present?

    param_body = params.require(:task).permit(:project_id, :note_id, :date_to, :completed, :lock_version)
    param_url_pass.merge(param_body)
  end

  def set_note
    # ノートの存在チェックも兼ねる
    @note = @project.notes.find(params[:note_id])
  end
end
