class TaskHeaderSerializer < ActiveModel::Serializer
  attributes :id, :date_to, :completed, :lock_version
end
