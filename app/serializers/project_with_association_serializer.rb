# frozen_string_literal: true

# プロジェクト関連の情報をシリアライズするクラス
class ProjectWithAssociationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name
  attributes :user

  def user
    response_data = current_user.as_json(only: %i[id name])
    response_data[:avatar] = if current_user.avatar.attached?
                               url_for(current_user.avatar)
                             else
                               ''
                             end
    response_data
  end

  has_many :folders, serializer: FolderWithTaskCountSerializer

  def folders
    object.folders.select_tasks_count
  end
end
