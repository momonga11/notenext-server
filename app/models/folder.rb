# frozen_string_literal: true

# フォルダのモデルクラス
class Folder < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  belongs_to :project
  has_many :notes, dependent: :destroy
  has_many :tasks, through: :notes
  has_many :tasks_not_completed, -> { where(completed: false) }, through: :notes, source: :task

  # 完了していないタスクの件数を合わせて取得する
  def self.select_tasks_count
    left_joins(:tasks_not_completed).group('folders.id').select('folders.*, COUNT(`tasks`.`id`) AS tasks_count').order(:id)
  end

  # 単一のフォルダから完了していないタスクの件数を合わせてJSONにして返す
  def with_tasks_count
    attributes.merge('tasks_count' => tasks.where(completed: false).count)
  end
end
