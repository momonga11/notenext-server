# frozen_string_literal: true

# ノート情報を管理するクラス
class V1::ProjectsController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:id])
  }, only: %i[show update destroy]

  # GET /projects
  def index
    @projects = current_user.projects.all

    render json: @projects
  end

  # GET /projects/1
  def show
    # 特定のパラメータが渡った時、初期描画用にプロジェクト、フォルダー、ユーザーの情報を抜粋して渡す。
    if params.key?(:with_association) && ActiveRecord::Type::Boolean.new.cast(params[:with_association])
      render json: @project, serializer: ProjectWithAssociationSerializer, scope: current_user
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
    has_lock_version!(params, :project)

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

  # Only allow a trusted parameter "white list" through.
  def project_params
    params.require(:project).permit(:name, :description, :lock_version)
  end
end
