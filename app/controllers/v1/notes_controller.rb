# frozen_string_literal: true

# ノート情報を管理するクラス
class V1::NotesController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:project_id])
  }
  before_action :set_folder, except: %i[show all attach_image]
  before_action :set_note, only: %i[show update destroy attach_image]

  # GET /notes
  def index
    # 特定のパラメータが渡った時、初期描画用にプロジェクト、フォルダー、ユーザーの情報を抜粋して渡す。
    if params.key?(:with_association) && ActiveRecord::Type::Boolean.new.cast(params[:with_association])
      render json: @folder, serializer: FolderWithAssociationSerializer,
             include: { notes: [:task] },
             sort_by: create_sort_by, page: params[:page], search: params[:search]
    else
      render json: @folder.notes.includes(:task).search_ambiguous_text(params[:search]).order(create_sort_by).page(params[:page])
    end
  end

  # GET all/notes
  def all
    if params.key?(:search) && params[:search]
      @notes = @project.notes.search_ambiguous_text(params[:search])
      render json: @notes.includes(:task).order(created_at: :desc).page(params[:page])

      return
    end

    render json: @project.notes.includes(:task).page(params[:page]).order(created_at: :desc)
  end

  # GET /notes/1
  def show
    if params[:folder_id].present? && @note.folder_id != params[:folder_id].to_i
      response_not_found("#{Folder.model_name.human} (#{Note.primary_key} : #{params[:folder_id]}) ")
      return
    end

    render json: @note
  end

  # POST /notes
  def create
    @note = @folder.notes.new(note_params)

    if @note.save
      response_created_request(@note, v1_project_url(@note))
    else
      response_unprocessable_entity(@note)
    end
  end

  # PATCH/PUT /notes/1
  def update
    has_lock_version!(params, :note)

    if @note.update(note_params)
      response_success_request(@note)
    else
      response_unprocessable_entity(@note.errors)
    end
  end

  # DELETE /notes/1
  def destroy
    if @note.destroy
      response_success_request
    else
      response_unprocessable_entity(@note)
    end
  end

  # PUT /notes/1/images/attach
  def attach_image
    raise ActionController::ParameterMissing, :images unless note_image_params.key?(:images)

    has_lock_version!(note_image_params, nil)

    if @note.update(note_image_params)
      image = @note.images.sort_by(&:id).reverse[0]

      response_success_request({ id: @note.id, image_url: url_for(image), lock_version: @note.lock_version })
    else
      response_unprocessable_entity(@note)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_note
    @note = Note.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def note_params
    param_url_pass = params.permit(:project_id, :folder_id)

    # noteに値がない場合にはURLパラメータを返す
    return param_url_pass if params.key?(:note) && !params[:note].present?

    param_body = params.require(:note).permit(:project_id, :folder_id, :title, :text,
                                              :htmltext, :lock_version)
    param_url_pass.merge(param_body)
  end

  def note_image_params
    params.require(:note).permit(:lock_version, { images: %i[data filename content_type identify] })
  end

  def set_folder
    # フォルダの存在チェックも兼ねる
    @folder = @project.folders.find(params[:folder_id])
  end

  # sortのパラメーターからソートの文字列を構築する
  def create_sort_by
    return unless params[:sort]

    # sort pamamは、'カラム名:ソート順(asc or desc)'という形式を想定している。
    sort_column, sort_order = params[:sort].split(':')

    # SQLインジェクション対策
    return unless Note.column_names.include?(sort_column) || Task.column_names.include?(sort_column)

    # 並び順が指定なし、あるは誤っている場合は、デフォルトとして昇順を設定する
    sort_order = 'asc' if !sort_order || (sort_order != 'asc' && sort_order != 'desc')

    if sort_column == 'date_to'
      sort_column = "tasks.#{sort_column}"
      # タスクが紐づく、かつ、タスクが未完了、かつソート対象のカラムがNULLではないものから、並び替えを実行する
      return Arel.sql(
        "tasks.id IS NULL, tasks.completed, #{sort_column} IS NULL, #{sort_column} #{sort_order} ,tasks.id ASC, notes.id"
      )
    end

    "#{sort_column} #{sort_order}"
  end
end
