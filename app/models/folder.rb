# frozen_string_literal: true

# フォルダのモデルクラス
class Folder < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  belongs_to :project
  has_many :notes, dependent: :destroy
end
