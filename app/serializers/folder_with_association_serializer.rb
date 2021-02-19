class FolderWithAssociationSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :lock_version
  # has_many :notes, serializer: NoteHeaderSerializer, scope: current_user
  has_many :notes, serializer: NoteHeaderSerializer
end
