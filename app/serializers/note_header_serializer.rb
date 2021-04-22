# frozen_string_literal: true

# ノートのヘッダー情報をシリアライズするクラス
class NoteHeaderSerializer < ActiveModel::Serializer
  attributes :id, :folder_id, :title, :text, :lock_version, :created_at, :updated_at
end
