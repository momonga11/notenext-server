# frozen_string_literal: true

# タスク情報をシリアライズするクラス
class TaskSerializer < ActiveModel::Serializer
  attributes :id, :project_id, :note_id, :date_to, :completed, :lock_version
end
