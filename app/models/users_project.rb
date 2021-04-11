# frozen_string_literal: true

# ユーザーのモデルクラス
class UsersProject < ApplicationRecord
  # self.primary_keys = :user_id, :project_id
  belongs_to :user
  belongs_to :project
  before_create :set_is_owner

  private

  def set_is_owner
    # 既に該当ユーザーがオーナーのプロジェクトが存在した場合は、is_ownerはfalseになる
    self.is_owner = !UsersProject.exists?(user_id: user_id, is_owner: true)
  end
end
