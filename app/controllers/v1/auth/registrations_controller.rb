class V1::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :set_user_by_token, only: %i[destroy update destroy_avatar]

  def destroy_avatar
    if @resource
      if @resource.avatar.attached?
        @resource.avatar.purge
        response_success_request
      else
        response_not_found(@resource.avatar.name)
      end
    else
      render_update_error_user_not_found
    end
  end

  private

  def resource_data(opts = {})
    response_data = super
    resource_data_with_avatar(response_data, @resource)
  end
end
