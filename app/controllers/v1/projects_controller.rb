class V1::ProjectsController < V1::ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[show update destroy]

  # GET /projects
  def index
    @projects = current_user.projects.all

    render json: @projects
  end

  # GET /projects/1
  def show
    # 特定のパラメータが渡った時、初期描画用にプロジェクト、フォルダー、ユーザーの情報を抜粋して渡す。
    if params.key?(:header_info) && params[:header_info]
      render json: @project, serializer: ProjectHeaderSerializer, scope: current_user
    else
      render json: @project
    end
  end

  # POST /projects
  def create
    # 現在のユーザーとプロジェクトを紐付けて作成する
    project_user_params = project_params.merge(users: Array.new(1, current_user))
    @project = Project.new(project_user_params)

    if @project.save
      response_created_request(@project, v1_project_url(@project))
    else
      response_unprocessable_entity(@project)
    end
  end

  # PATCH/PUT /projects/1
  def update
    if !params.key?(:project) || !params[:project].key?(:lock_version)
      response_bad_request('必要なパラメーターが存在しないため、処理を実行できません(lock_version)')
      return
    end

    if @project.update(project_params)
      response_success_request(@project)
    else
      response_unprocessable_entity(@project)
    end
  end

  # DELETE /projects/1
  def destroy
    if @project.destroy
      response_success_request
    else
      response_unprocessable_entity(@project)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    # @project = Project.find(params[:id])
    @project = authenticate_project!(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def project_params
    params.require(:project).permit(:name, :description, :lock_version)
  end
end
