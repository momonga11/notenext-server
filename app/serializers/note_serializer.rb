# frozen_string_literal: true

# ノート関連の情報をシリアライズするクラス
class NoteSerializer < ActiveModel::Serializer
  attributes :id, :project_id, :folder_id, :title, :text, :htmltext, :lock_version, :created_at, :updated_at
  has_one :task
end
