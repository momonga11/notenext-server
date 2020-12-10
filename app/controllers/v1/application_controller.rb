class V1::ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ResponseRenderer
  # skip_before_action :verify_authenticity_token, if: :devise_controller? # APIではCSRFチェックをしない

  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from StandardError, with: :render_standard_error
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from ActiveRecord::StaleObjectError, with: :render_stale_object_error

  private

  def devise_token_auth_controller?
    params[:controller].split('/')[0] == 'devise_token_auth'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name avatar])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name avatar])
  end

  def authenticate_project!(project_id)
    # TODO: 指定したプロジェクトにcurrent_userが所属しているか確認する。
    project = current_user.projects.find_by(id: project_id)

    project || response_forbidden

    # unless project
    #   # TODO: 権限がないエラー
    #   # puts "not authenticate project:#{project_id}"
    #   response_unauthorized
    # end

    # project
  end

  def render_parameter_missing(e)
    response_bad_request("必要なパラメーターが存在しない、または空のため、処理を実行できません(#{e.param})")
  end

  def render_stale_object_error(e)
    response_conflict(e.record.class.to_s)
  end

  def render_standard_error(_e)
    response_internal_server_error
  end
end
