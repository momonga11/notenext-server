class NoteHeaderSerializer < ActiveModel::Serializer
  attributes :id, :folder_id, :title, :text, :lock_version,:created_at, :updated_at
  # attributes :id, :title, :text, :created_at, :updated_at, :created_by, :avatar

  # def created_by
  #   current_user.name
  # end

  # def avatar
  #   if current_user.avatar.attached?
  #     url_for(current_user.avatar)
  #   else
  #     ''
  #   end
  # end
end
