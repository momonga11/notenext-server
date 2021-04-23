class TaskSerializer < ActiveModel::Serializer
  attributes :id, :project_id, :note_id, :date_to, :completed, :lock_version
end
