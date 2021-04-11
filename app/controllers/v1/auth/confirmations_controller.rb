# frozen_string_literal: true

# DeviseTokenAuth::ConfirmationControllerの継承クラス
class V1::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  def show
    super
  rescue ActionController::RoutingError => _e
    redirect_to(Rails.application.config.redirect_system_error_url)
  end
end
