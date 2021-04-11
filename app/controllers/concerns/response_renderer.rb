# frozen_string_literal: true

# レスポンスのレンダリングメソッドを定義したモジュール
module ResponseRenderer
  # 200 Success
  def response_success_request(response_object = nil)
    if response_object
      render status: :ok, json: response_object
    else
      render status: :ok
    end
  end

  # 201 Created
  def response_created_request(response_object, location_url)
    render status: :created, json: response_object, location: location_url
  end

  # 400 Bad Request
  def response_bad_request(message)
    render status: :bad_request, json: create_error_response(message)
  end

  # 403 Forbidden
  def response_forbidden
    render status: :forbidden, json: create_error_response(I18n.t('response_errors.messages.forbidden'))
  end

  # 404 Not Found
  def response_not_found(resource)
    render status: :not_found,
           json: create_error_response(I18n.t('response_errors.messages.not_found', attribute: resource))
  end

  # 409 Conflict
  def response_conflict(model_name)
    render status: 409, json: create_error_response(I18n.t('response_errors.messages.conflict', attribute: model_name))
  end

  # 422 Unprocessable_entity
  def response_unprocessable_entity(model)
    render status: :unprocessable_entity, json: create_error_response(model.errors.full_messages)
  end

  # 500 Internal Server Error
  def response_internal_server_error(error)
    logger.error(error)
    render status: 500, json: create_error_response(I18n.t('response_errors.messages.internal_server'))
  end

  private

  def create_error_response(messages)
    { errors: [messages] }
  end
end
