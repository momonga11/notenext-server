# frozen_string_literal: true

# プロジェクトのモデルクラス
class Project < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  validate :over_upper_limit, on: :create
  has_many :folders, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :users_projects, dependent: :destroy
  has_many :users, through: :users_projects

  private

  def over_upper_limit
    if !users.empty? && UsersProject.exists?(user_id: users[0].id, is_owner: true)
      errors.add(:base, 'ユーザーが作成できるプロジェクト数の上限を越えているため、作成できません。')
    end
  end
end
