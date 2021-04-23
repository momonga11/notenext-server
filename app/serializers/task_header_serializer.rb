class TaskHeaderSerializer < ActiveModel::Serializer
  attributes :id, :date_to, :completed
end
