class V1::ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ResponseRenderer

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?
  skip_before_action :verify_authenticity_token, if: :devise_controller? # APIではCSRFチェックをしない

  rescue_from StandardError, with: :render_standard_error
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from ActionController::RoutingError, with: :render_routing_error
  rescue_from ActiveRecord::StaleObjectError, with: :render_stale_object_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found

  private

  def devise_token_auth_controller?
    params[:controller].split('/')[0] == 'devise_token_auth'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: [:email, :name, { avatar: %i[data filename content_type identify] }])
  end

  def authenticate_project!(project_id)
    return unless user_signed_in?

    # 指定したプロジェクトにcurrent_userが所属しているか確認する。
    @project = current_user.projects.find_by(id: project_id)
    @project || response_forbidden
  end

  def render_standard_error(e)
    response_internal_server_error(e)
  end

  def render_routing_error(_e)
    response_bad_request('指定されたURLは存在しません')
  end

  def render_parameter_missing(e)
    response_bad_request("必要なパラメーターが存在しない、または空のため、処理を実行できません(#{e.param})")
  end

  def render_stale_object_error(e)
    response_conflict(e.record.class.to_s)
  end

  def render_record_not_found(e)
    response_not_found("#{e.model} の #{e.primary_key} が #{e.id} のレコード")
  end

  def has_lock_version!(params, key)
    raise ActionController::ParameterMissing, :lock_version if !params.key?(key) || !params[key].key?(:lock_version)
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
