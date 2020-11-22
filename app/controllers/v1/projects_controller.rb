class V1::ProjectsController < ApplicationController
  before_action :set_project, only: %i[show update destroy]

  # GET /projects
  # def index
  #   @projects = Project.all

  #   render json: @projects
  # end

  # GET /projects/1
  def show
    render json: @project
  end

  # POST /projects
  def create
    # TODO: 認証されていない場合はエラー(401)
    # 1ユーザー1プロジェクトのため、認証ユーザーがオーナーのプロジェクトが1以上の場合はエラー(403)

    @project = Project.new(project_params)

    if @project.save
      render json: @project, status: :created, location: v1_project_url(@project)
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /projects/1
  def update
    # TODO: 認証されていない場合はエラー(401)
    # TODO: 認証ユーザーが所属するプロジェクトでない場合はエラー(403)
    # TODO: 楽観排他制御
    if @project.update(project_params)
      render json: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # DELETE /projects/1
  def destroy
    # TODO: 認証されていない場合はエラー(401)
    # TODO: 認証ユーザーが所属するプロジェクトでない場合はエラー(403)
    # TODO: 楽観排他制御
    @project.destroy
    # TODO: 成功したのかどうかを返せ。
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def project_params
    params.require(:project).permit(:name, :description)
  end
end
