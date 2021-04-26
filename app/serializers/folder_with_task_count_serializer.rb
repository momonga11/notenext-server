# frozen_string_literal: true

# フォルダ情報と有効なタスクの数をシリアライズするクラス
class FolderWithTaskCountSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :lock_version, :tasks_count
end
