class V1::FoldersController < V1::ApplicationController
  before_action lambda {
    authenticate_project!(params[:project_id])
  }
  before_action :set_folder, only: %i[show update destroy]

  # GET /folders
  def index
    @folders = @project.folders

    render json: @folders
  end

  # GET /folders/1
  def show
    render json: @folder
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
