class V1::Auth::SessionsController < DeviseTokenAuth::SessionsController
  def create_sample
    # サンプルユーザーを払い出す
    User.transaction do
      user_sample = UserSample.where(payout: false).first
      if user_sample && user_sample.user &&
         user_sample.update(payout: true)
        # サンプルユーザーのメールアドレスとパスワードでパラメータを設定（パスワードは、既定のパスワードとする）
        params.merge!(email: user_sample.user.email, password: Rails.application.config.sample_user_password)

        # sign_in
        create
      else
        response_not_found(UserSample.model_name.human)
      end
    end
  end
end
