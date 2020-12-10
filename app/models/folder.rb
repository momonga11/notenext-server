class Folder < ApplicationRecord
  belongs_to :project
  has_many :notes, dependent: :destroy

  # destroy時、紐づくノートも併せて削除する
end
