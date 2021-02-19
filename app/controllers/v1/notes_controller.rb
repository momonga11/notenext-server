class V1::NotesController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:project_id])
  }
  before_action :set_folder, except: %i[show all]
  before_action :set_note, only: %i[show update destroy]

  # GET /notes
  def index
    # TODO: 無限スクロール対応
    # 特定のパラメータが渡った時、初期描画用にプロジェクト、フォルダー、ユーザーの情報を抜粋して渡す。
    if params.key?(:with_association) && ActiveRecord::Type::Boolean.new.cast(params[:with_association])
      # TODO: ユーザー情報も含める（画像も。with_attached_avatarを使うこと）
      render json: @folder, serializer: FolderWithAssociationSerializer
    else
      render json: @folder.notes
    end
  end

  # GET all/notes
  def all
    render json: @project.notes.order(created_at: :desc)
  end

  # GET /notes/1
  def show
    if params[:folder_id].present? && !(@note.folder_id == params[:folder_id].to_i)
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_note
    @note = Note.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def note_params
    param_url = params.permit(:project_id, :folder_id)
    # note以外のパラメータは受け付けないようにし、かつ、noteに値がない場合にはパラメータを許可する
    param_body = unless params.key?(:note) && !params[:note].present?
                   params.require(:note).permit(:project_id, :folder_id, :title, :text,
                                                :htmltext, :lock_version)
                 end
    param_url.merge(param_body)
  end

  def set_folder
    # フォルダの存在チェックも兼ねる
    @folder = @project.folders.find(params[:folder_id])
  end
end
