# frozen_string_literal: true

# フォルダ名の情報をサニタイズするクラス
class FolderNameSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
