class Note < ApplicationRecord
  validates :title, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  belongs_to :project
  belongs_to :folder
end
