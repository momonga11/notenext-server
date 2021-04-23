# frozen_string_literal: true

# タスクのモデルクラス
class Task < ApplicationRecord
  validates :lock_version, presence: true, on: :update
  validates :note_id, uniqueness: { case_sensitive: true }
  belongs_to :project
  belongs_to :note
end
