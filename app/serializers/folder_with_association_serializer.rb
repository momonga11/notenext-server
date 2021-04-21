# frozen_string_literal: true

# フォルダと紐づくノート関連の情報をサニタイズするクラス
class FolderWithAssociationSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :lock_version
  has_many :notes, serializer: NoteHeaderSerializer
  def notes
    object.notes.search_ambiguous_text(@instance_options[:search])
          .order(@instance_options[:sort_by])
          .page(@instance_options[:page])
  end
end
