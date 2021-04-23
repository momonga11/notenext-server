# frozen_string_literal: true

# フォルダ情報を管理するクラス
class V1::FoldersController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:project_id])
  }
  before_action :set_folder, only: %i[show update destroy]

  # GET /folders
  def index
    # 特定のパラメータが指定されている場合、ノートが紐づくフォルダのみ取得する（ノート検索用のパラメータも受け取れるようにする）
    unless params.key?(:note) && ActiveRecord::Type::Boolean.new.cast(params[:note])
      render json: @project.folders.select_tasks_count, each_serializer: FolderWithTaskCountSerializer
      return
    end

    # 以下、ノートが紐づくフォルダのみ取得する
    @folders = if params.key?(:search) && params[:search]
                 @project.folders.select_tasks_count
                         .where.not(notes: { id: nil })
                         .merge(Note.search_ambiguous_text(params[:search]))
               else
                 @project.folders.select_tasks_count.where.not(notes: { id: nil })
               end

    render json: @folders
  end

  # GET /folders/1
  def show
    render json: @folder.with_tasks_count
  end

  # POST /folders
  def create
    @folder = @project.folders.new(folder_params)

    if @folder.save
      response_created_request(@folder, v1_project_url(@folder))
    else
      response_unprocessable_entity(@folder)
    end
  end

  # PATCH/PUT /folders/1
  def update
    has_lock_version!(params, :folder)

    if @folder.update(folder_params)
      response_success_request(@folder)
    else
      response_unprocessable_entity(@folder)
    end
  end

  # DELETE /folders/1
  def destroy
    if @folder.destroy
      response_success_request
    else
      response_unprocessable_entity(@folder)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_folder
    @folder = Folder.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def folder_params
    params.require(:folder).permit(:name, :description, :lock_version)
  end
end
