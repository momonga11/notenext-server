# frozen_string_literal: true

# DeviseTokenAuth::TokenValidationsControllerの継承クラス
class V1::Auth::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  def resource_data(opts = {})
    response_data = super
    resource_data_with_avatar(response_data, @resource)
  end
end
