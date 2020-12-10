class ProjectHeaderSerializer < ActiveModel::Serializer
  attributes :id, :name
  attributes :user

  def user
    current_user.as_json(only: %i[id name avatar])
  end

  has_many :folders, serializer: FolderNameSerializer
end
