class Note < ApplicationRecord
  belongs_to :project
  belongs_to :folder

  # TODO: destroy時、紐づくタスクを削除するかどうか（引数で判断）
end
