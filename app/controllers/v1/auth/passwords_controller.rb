# frozen_string_literal: true

# DeviseTokenAuth::PasswordsControllerの継承クラス
class V1::Auth::PasswordsController < DeviseTokenAuth::PasswordsController
  protected

  # エラー画面にリダイレクトする
  def render_edit_error
    redirect_to(Rails.application.config.redirect_system_error_url)
  end
end
