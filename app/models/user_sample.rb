# frozen_string_literal: true

# ユーザーサンプルのモデルクラス
class UserSample < ApplicationRecord
  belongs_to :user
end
