module ResponseRenderer
  # 200 Success
  def response_success_request(responseObject = nil)
    if responseObject
      render status: :ok, json: responseObject
    else
      render status: :ok
    end
  end

  # 201 Created
  def response_created_request(responseObject, locationUrl)
    render status: :created, json: responseObject, location: locationUrl
  end

  # 400 Bad Request
  def response_bad_request(message)
    render status: 400, json: { message: message }
  end

  # 401 Unauthorized
  def response_unauthorized
    render status: :unauthorized
  end

  # 403 Forbidden
  def response_forbidden
    # TODO: エラーメッセージの呼び出し
    render status: :forbidden, json: { message: '' }
  end

  # 404 Not Found
  def response_not_found(resource)
    render status: :not_found, json: { message: "#{resource} は見つかりませんでした。" }
  end

  # 409 Conflict
  def response_conflict(class_name)
    render status: 409, json: { message: "#{class_name.capitalize}は最新の状態ではないため更新できません。アプリケーションをリロードしてくだい。" }
  end

  # 422 Unprocessable_entity
  def response_unprocessable_entity(model)
    render json: model.errors.full_messages, status: :unprocessable_entity
  end

  # 500 Internal Server Error
  def response_internal_server_error
    render status: 500, json: { message: 'Internal Server Error' }
  end
end
