class Folder < ApplicationRecord
  belongs_to :project

  # destroy時、紐づくノートも併せて削除する
end
