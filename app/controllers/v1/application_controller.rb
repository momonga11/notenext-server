# frozen_string_literal: true

# version:1のアプリケーションコントローラー
class V1::ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ResponseRenderer

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?

  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from ActionController::RoutingError, with: :render_routing_error
  rescue_from ActiveRecord::StaleObjectError, with: :render_stale_object_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found

  private

  def devise_token_auth_controller?
    params[:controller].split('/')[0] == 'devise_token_auth'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name uid])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: [:email, :name, { avatar: %i[data filename content_type identify] }])
  end

  def authenticate_project!(project_id)
    return unless user_signed_in?

    # 指定したプロジェクトにcurrent_userが所属しているか確認する。
    @project = current_user.projects.find_by(id: project_id)
    @project || response_forbidden
  end

  def render_routing_error(_error)
    response_bad_request(I18n.t('response_errors.messages.not_routing'))
  end

  def render_parameter_missing(error)
    response_bad_request(I18n.t('response_errors.messages.parameter_missing', attribute: error.param))
  end

  def render_stale_object_error(error)
    response_conflict(error.record.model_name.human)
  end

  def render_record_not_found(error)
    response_not_found("#{I18n.t("activerecord.models.#{error.model.downcase}")} (#{error.primary_key} : #{error.id}) ")
  end

  def has_lock_version!(params, key)
    if key
      raise ActionController::ParameterMissing, :lock_version if !params.key?(key) || !params[key].key?(:lock_version)
    elsif !params.key?(:lock_version)
      raise ActionController::ParameterMissing, :lock_version
    end
  end

  def resource_data_with_avatar(response_data, user)
    response_data[:avatar] = if user.avatar.attached?
                               url_for(user.avatar)
                             else
                               ''
                             end
    response_data
  end
end
