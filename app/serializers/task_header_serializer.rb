# frozen_string_literal: true

# タスクのヘッダー情報をシリアライズするクラス
class TaskHeaderSerializer < ActiveModel::Serializer
  attributes :id, :date_to, :completed, :lock_version
end
