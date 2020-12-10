class V1::FoldersController < V1::ApplicationController
  before_action lambda {
                  authenticate_project!(params[:id])
                }, only: %i[show update destroy]
  before_action :set_folder, only: %i[show update destroy]

  # GET /folders
  def index
    @folders = Folder.all

    render json: @folders
  end

  # GET /folders/1
  def show
    render json: @folder
  end

  # POST /folders
  def create
    @folder = Folder.new(folder_params)

    if @folder.save
      render json: @folder, status: :created, location: v1_folder_url(@folder)
    else
      render json: @folder.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /folders/1
  def update
    if @folder.update(folder_params)
      render json: @folder
    else
      render json: @folder.errors, status: :unprocessable_entity
    end
  end

  # DELETE /folders/1
  def destroy
    @folder.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_folder
    @folder = Folder.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def folder_params
    params.require(:folder).permit(:project_id, :name, :description)
  end
end
