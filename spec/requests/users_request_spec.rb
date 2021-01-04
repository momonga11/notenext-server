require 'rails_helper'
require 'base64'

RSpec.describe 'Users', type: :request do
  include JsonSupport

  let(:user) { FactoryBot.create(:user) }
  let(:auth_params) do
    login(user)
    get_auth_params_from_login_response_headers(response)
  end

  describe 'GET token_validations#validate_token' do
    it '認証されていない場合、失敗する' do
      get v1_auth_validate_token_path
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証情報が誤っている場合、失敗する' do
      login(user)
      auth_params = get_auth_params_from_login_response_headers(response)
      auth_params['access-token'] = '12345'
      get v1_auth_validate_token_path, headers: auth_params
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      it 'success' do
        get v1_auth_validate_token_path, headers: auth_params
        expect(response).to have_http_status(:ok)

        # User情報が取得できるかどうか。
        body = json_parse_body(response)
        expect(body[:data][:name]).to eq(user.name)
        expect(body[:data][:email]).to eq(user.email)
      end

      context 'userにavatarが設定されている場合' do
        let(:filename) { 'neko_test.jpg' }

        before do
          # avatarを更新する
          put v1_auth_path, params: add_param_avatar({}, filename), headers: auth_params
        end

        it 'avatarが取得できること' do
          get v1_auth_validate_token_path, headers: auth_params
          expect(response).to have_http_status(:ok)

          # User情報が取得できるかどうか。
          body = json_parse_body(response)
          expect(body[:data][:name]).to eq(user.name)
          expect(body[:data][:email]).to eq(user.email)
          expect(body[:data][:avatar].split('/').last).to eq(filename)
        end
      end
    end

    describe 'トークンの有効期限' do
      shared_examples 'use authentication tokens of different ages' do |token_age, http_status|
        let(:vary_authentication_age) { token_age }

        it 'ユーザー情報を取得する' do
          expect(vary_authentication_age(token_age)).to have_http_status(http_status)
        end

        def vary_authentication_age(token_age)
          get v1_auth_validate_token_path, headers: auth_params
          expect(response).to have_http_status(:success)

          allow(Time).to receive(:now).and_return(Time.now + token_age)

          get v1_auth_validate_token_path, headers: auth_params
          response
        end
      end

      context 'case トークンの有効期限内' do
        it_behaves_like 'use authentication tokens of different ages', 1.weeks, :success
      end

      context 'case トークンの有効期限外' do
        it_behaves_like 'use authentication tokens of different ages', 3.weeks, :unauthorized
      end
    end
  end

  describe 'POST registration#create' do
    let(:user_attributes) do
      user_attributes = FactoryBot.attributes_for(:user_new)
      user_attributes
    end

    context 'parameterが正常値の場合' do
      let!(:user) { FactoryBot.create(:user) } # 比較用ユーザー

      it 'emailの重複ユーザーがいない場合、作成できる' do
        expect do
          post v1_auth_sign_up_path, params: user_attributes
        end.to change(User.where(name: user_attributes[:name]), :count).by(1)
        expect(response).to have_http_status(:ok)

        # 認証を実行することで有効になる
        user_created = User.find(json_parse_body(response)[:data][:id])
        expect(user_created.uid).to eq ''

        get v1_auth_confirmation_path, params: { confirmation_token: user_created.confirmation_token }

        # 認証を実行後にuidが設定されていることを確認する
        expect(User.find(user.id).uid).not_to eq ''
      end

      it 'emailの重複ユーザーがいる場合、作成できない' do
        user_attributes[:email] = user.email
        expect do
          post v1_auth_sign_up_path, params: user_attributes
        end.to change(User.where(name: user_attributes[:name]), :count).by(0)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'parameterが異常値の場合' do
      subject { proc { post v1_auth_sign_up_path, params: user_attributes } }

      shared_examples 'not create user' do |errorMessage|
        it do
          expect(subject).to change(User.all, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_parse_body(response)[:errors].to_s).to include errorMessage if errorMessage
        end
      end

      context '必要なparameterが完全に異なる場合' do
        let(:user_attributes) { { test: 'test' } }

        it_behaves_like 'not create user'
      end

      context 'nameが存在しない場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_not_name) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'nameが空の場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_name_null) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'emailが存在しない場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_not_email) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'emailが空の場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_email_null) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'passwordが存在しない場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_not_password) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'passwordが空の場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_password_null) }

        it_behaves_like 'not create user', 'を入力してください'
      end

      context 'password_confirmationがpasswordと一致しない場合' do
        let(:user_attributes) { FactoryBot.attributes_for(:user_new_password_confirmation_null) }

        it_behaves_like 'not create user', '一致しません'
      end
    end
  end

  describe 'PUT registration#update' do
    let(:user_for_update_attribute) { FactoryBot.attributes_for(:user_for_update, :update_email) }

    it '認証されていない場合、失敗する' do
      put v1_auth_path, params: user_for_update_attribute
      expect(response).to have_http_status(:not_found)
    end

    context '認証を事前に実施する場合' do
      subject do
        put v1_auth_path, params: user_for_update_attribute, headers: auth_params
        response
      end

      context '認証情報が誤っている場合' do
        let(:auth_params) do
          login(user)
          auth_params = get_auth_params_from_login_response_headers(response)
          auth_params['access-token'] = '12345'
          auth_params
        end

        it '失敗する' do
          expect(subject).to have_http_status(:not_found)
        end
      end

      context 'parameterにpasswordが存在しない場合' do
        context 'parameterにemailが存在する場合' do
          it '更新に成功する' do
            expect(subject).to have_http_status(:ok)

            token = User.find(user.id).confirmation_token
            get v1_auth_confirmation_path, params: { confirmation_token: token }

            # Userが変更されてるかどうか。
            user_updated = User.find(user.id)
            expect(user_updated.name).to eq(user_for_update_attribute[:name])
            expect(user_updated.email).to eq(user_for_update_attribute[:email])
          end
        end

        context 'case not exist email in parameter' do
          let(:user_for_update_attribute) { FactoryBot.attributes_for(:user_for_update) }

          it '更新に成功する' do
            expect(subject).to have_http_status(:ok)

            # User情報が変更されているかどうか。
            body = json_parse_body(response)
            expect(body[:data][:id]).to eq(user.id)
            expect(body[:data][:name]).to eq(user_for_update_attribute[:name])
          end
        end

        context 'case exist avatar in parameter', focus: :true do
          let(:filename) { 'neko_test.jpg' }
          let(:user_for_update_attribute) do
            add_param_avatar(FactoryBot.attributes_for(:user_for_update, :update_email), filename)
          end

          it '更新に成功する' do
            expect(subject).to have_http_status(:ok)

            token = User.find(user.id).confirmation_token
            get v1_auth_confirmation_path, params: { confirmation_token: token }

            # User情報が変更されているかどうか。
            user_updated = User.find(user.id)
            expect(url_for(user_updated.avatar).split('/').last).to eq(filename)
            expect(
              IO.read(ActiveStorage::Blob.service.send(:path_for, user_updated.avatar.key))
            ).to match(IO.read("spec/fixtures/#{filename}"))
          end
        end
      end

      context 'parameterにpasswordとcurrent_passwordが存在した場合' do
        let(:user_for_update_attribute) { FactoryBot.attributes_for(:user_for_update, :update_password) }

        it 'can change password' do
          expect(subject).to have_http_status(:ok)

          # 新しいパスワードで、ログインできるかどうか
          user_new = User.new(email: user.email, password: user_for_update_attribute[:password])
          login(user_new)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'parameterが異常値の場合' do
        shared_examples 'not update user' do |errorMessage|
          it '失敗する' do
            expect(subject).to have_http_status(:unprocessable_entity)
            expect(json_parse_body(response)[:errors][:full_messages].to_s).to include errorMessage if errorMessage
          end
        end

        context 'emailの重複ユーザーがいる場合' do
          before do
            FactoryBot.create(:user_for_update, :create_user)
          end

          it_behaves_like 'not update user', 'すでに存在します'
        end

        context '必要なparameterが完全に異なる場合' do
          let(:user_for_update_attribute) { { test: 'test' } }

          it_behaves_like 'not update user'
        end

        context 'password_confirmationがpasswordと一致しない場合' do
          let(:user) { FactoryBot.create(:user_for_update, :create_user) }
          let(:user_for_update_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_equal_password_confirmation)
          end

          it_behaves_like 'not update user', '一致しません'
        end

        context 'current_passwordが現在のパスワードと一致しない場合' do
          let(:user) { FactoryBot.create(:user_for_update, :create_user) }
          let(:user_for_update_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_equal_current_password)
          end

          it_behaves_like 'not update user', 'Current passwordは不正な値です'
        end

        context 'parameterにpasswordが存在するが、current_passwordが存在しない場合' do
          let(:user) { FactoryBot.create(:user_for_update, :create_user) }
          let(:user_for_update_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_exist_current_password)
          end

          it_behaves_like 'not update user', 'Current passwordを入力してください'
        end
      end
    end
  end

  describe 'DELETE registration#purge_avatar' do
    let(:avatar_attribute) do
      avatar64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
      { data: "data:image/jpeg;base64,#{avatar64}", filename: 'neko_test.jpg' }
    end

    context '認証されていない場合' do
      before do
        user.update(avatar: avatar_attribute)
      end

      it 'failure' do
        delete v1_auth_purge_avatar_path
        expect(response).to have_http_status(:not_found)
      end
    end

    context '認証を事前に実施した場合' do
      subject do
        delete v1_auth_purge_avatar_path, headers: auth_params
        response
      end

      context '認証情報が誤っている場合' do
        before do
          user.update(avatar: avatar_attribute)
        end

        let(:auth_params) do
          login(user)
          auth_params = get_auth_params_from_login_response_headers(response)
          auth_params['access-token'] = '12345'
          auth_params
        end

        it '失敗する' do
          expect(subject).to have_http_status(:not_found)
          expect(user.avatar.attached?).to be_truthy
        end
      end

      context '認証情報が正しい場合' do
        before do
          user.update(avatar: avatar_attribute)
        end

        it 'avatarの削除に成功する' do
          expect(subject).to have_http_status(:ok)
          expect(User.find(user.id).avatar.attached?).to be_falsey
        end
      end

      context 'avatarが設定されていない場合', focus: :true do
        it 'avatarの削除に失敗する' do
          expect(subject).to have_http_status(:not_found)
          expect(User.find(user.id).avatar.attached?).to be_falsey
        end
      end
    end
  end

  describe 'DELETE registration#destroy' do
    # expect内で作成しないよう、事前に作成しておく
    let!(:user) { FactoryBot.create(:user) }

    it '認証されていない場合、失敗する' do
      delete v1_auth_destory_path
      expect(response).to have_http_status(:not_found)
    end

    context '認証を事前に実施した場合' do
      subject { proc { delete v1_auth_destory_path, headers: auth_params } }

      context '認証情報が誤っている場合' do
        let(:auth_params) do
          login(user)
          auth_params = get_auth_params_from_login_response_headers(response)
          auth_params['access-token'] = '12345'
          auth_params
        end

        it '失敗する' do
          expect(subject).to change(User.all, :count).by(0)
          expect(response).to have_http_status(:not_found)
        end
      end

      context '認証情報が正しい場合' do
        it '削除に成功する' do
          expect(subject).to change(User.all, :count).by(-1)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'POST session#create' do
    it 'UserのKeyが正しい場合はloginできる' do
      login(user)
      expect(response).to have_http_status(:ok)
    end

    context 'Userのemailが誤っている場合' do
      before do
        user.email = 'error@example.com'
      end

      it 'ログインできない' do
        login(user)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'Userのpasswordが誤っている場合' do
      before do
        user.password = 'errorPassword'
      end

      it 'ログインできない' do
        login(user)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    # Dummy Comment For Formatter Error
    context 'ログインに指定回数失敗した場合' do
      before do
        user.password = 'bad-Password'

        # 20回ログインに失敗させる
        20.times do
          login(user)
        end
      end

      it 'ログインできなくなる' do
        user.password = FactoryBot.attributes_for(:user)[:password]
        login(user)
        expect(response).to have_http_status(:unauthorized)
      end

      it '時間経過によってログインできるようになる' do
        allow(Time).to receive(:now).and_return(Time.now + 1.hour)

        user.password = FactoryBot.attributes_for(:user)[:password]
        login(user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'DELETE session#destroy' do
    context 'ログインしていない場合' do
      it 'ログアウトできない' do
        delete v1_auth_sign_out_path
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'ログインしている場合' do
      subject do
        delete v1_auth_sign_out_path, headers: auth_params
        response
      end

      shared_examples 'execute logout' do |http_status|
        it { is_expected.to have_http_status(http_status) }
      end

      context '認証情報が誤っている場合' do
        let(:auth_params) do
          login(user)
          auth_params = get_auth_params_from_login_response_headers(response)
          auth_params['access-token'] = '12345'
          auth_params
        end

        it_behaves_like 'execute logout', :not_found
      end

      context '認証情報が正しい場合' do
        it_behaves_like 'execute logout', :success
        it 'ログアウト後、ログインなしでアクセスできないこと' do
          expect(subject).to have_http_status(:success)

          get v1_auth_validate_token_path, headers: auth_params
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'GET passwords#edit' do
    let(:user) { FactoryBot.create(:user_for_update, :create_user) }
    let(:user_for_password_attribute) { FactoryBot.attributes_for(:user_for_update, :update_password) }

    before do
      # password reset
      post v1_auth_password_create_path, params: { email: user.email }
      @mail = ActionMailer::Base.deliveries.last
      @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
      @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)"/)[1]
    end

    context 'parameterが正しい場合' do
      it 'success' do
        get v1_edit_auth_password_path, params: { reset_password_token: @mail_reset_token,
                                                  redirect_url: @mail_redirect_url }
        expect(response).to have_http_status(:found)
      end
    end

    context 'parameterが誤っている場合' do
      context 'uncorrect reset_password_token' do
        it 'failure' do
          get v1_edit_auth_password_path, params: { reset_password_token: 'badToken' }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context '必要なparameterが完全に異なる場合' do
        it 'failure' do
          get v1_edit_auth_password_path, params: { test: 'test' }
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe 'POST passwords#create' do
    context '指定したemailのユーザーが存在する場合' do
      it 'send email' do
        @redirect_url = 'http://ng-token-auth.dev'
        post v1_auth_password_create_path, params: { email: user.email, redirect_url: @redirect_url }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PUT passwords#update' do
    let(:user) { FactoryBot.create(:user_for_update, :create_user) }
    let(:user_for_password_attribute) { FactoryBot.attributes_for(:user_for_update, :update_password) }

    it '認証されていない場合、失敗する' do
      put v1_auth_password_update_path, params: user_for_password_attribute
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証を事前に実施した場合' do
      subject do
        put v1_auth_password_update_path, params: user_for_password_attribute, headers: auth_params
        response
      end

      context '認証情報が誤っている場合' do
        let(:auth_params) do
          login(user)
          auth_params = get_auth_params_from_login_response_headers(response)
          auth_params['access-token'] = '12345'
          auth_params
        end

        it '失敗する' do
          expect(subject).to have_http_status(:unauthorized)
        end
      end

      context '認証ヘッダーが存在する場合' do
        context 'parameterにcurrent_passwordとpasswordとpassword_confirmationが存在した場合' do
          it 'パスワードを変更できる' do
            expect(subject).to have_http_status(:ok)

            # 新しいパスワードでログインできるかどうか
            user_new = User.new(email: user.email,
                                password: user_for_password_attribute[:password])
            login(user_new)
            expect(response).to have_http_status(:ok)
          end
        end
      end

      context 'parameterが異常値の場合' do
        shared_examples 'not update user' do |errorMessage|
          it '失敗する' do
            expect(subject).to have_http_status(:unprocessable_entity)
            expect(json_parse_body(response)[:errors].to_s).to include errorMessage if errorMessage
          end
        end

        context '必要なparameterが完全に異なる場合' do
          let(:user_for_password_attribute) { { test: 'test' } }

          it_behaves_like 'not update user'
        end

        context 'password_confirmationがpasswordと一致しない場合' do
          let(:user_for_password_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_equal_password_confirmation)
          end

          it_behaves_like 'not update user', '一致しません'
        end

        context 'current_passwordが現在のパスワードと一致ない場合' do
          let(:user_for_password_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_equal_current_password)
          end

          it_behaves_like 'not update user', 'Current passwordは不正な値です'
        end

        context 'parameterにcurrent_passwordが存在しない場合' do
          let(:user_for_password_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_exist_current_password)
          end

          it_behaves_like 'not update user', 'パラメータが与えられていません'
        end

        context 'parameterにpasswordが存在しない場合' do
          let(:user_for_password_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_exist_password)
          end

          it_behaves_like 'not update user', 'パラメータが与えられていません'
        end

        context 'parameterにpassword_confirmationが存在しない場合' do
          let(:user_for_password_attribute) do
            FactoryBot.attributes_for(:user_for_update, :not_exist_password_confirmation)
          end

          it_behaves_like 'not update user', 'パラメータが与えられていません'
        end
      end
    end
  end

  describe 'GET confirmations#show' do
    let(:user_attributes) { FactoryBot.attributes_for(:user) }

    before do
      # ユーザーを作成したのち、認証URLを実行する
      post v1_auth_sign_up_path, params: user_attributes
      expect(response).to have_http_status(:ok)

      @mail = ActionMailer::Base.deliveries.last
      @confirmation_token = @mail.body.match(/confirmation_token=([^&]*)&/)[1]
    end

    context 'parameterが正しい場合' do
      it 'リダイレクトできる' do
        get v1_auth_confirmation_path, params: { confirmation_token: @confirmation_token }
        expect(response).to have_http_status(:found)
      end
    end

    context 'parameterが存在しない場合' do
      it 'リダイレクトできない' do
        get v1_auth_confirmation_path
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'parameterが誤っている場合' do
      it 'リダイレクトできない' do
        get v1_auth_confirmation_path, params: { test: 'test' }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'POST confirmations#create' do
    context 'parameterが正しい場合' do
      it 'メールが送信できる' do
        post v1_auth_confirmation_create_path, params: { email: user.email }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'parameterが誤っている場合' do
      it '必要なparameterが完全に異なる場合、メールが送信できない' do
        post v1_auth_confirmation_create_path, params: { test: 'test' }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'メールアドレスが空の場合、メールは送信できない' do
        post v1_auth_confirmation_create_path, params: { email: '' }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  private

  def login(user)
    post v1_auth_sign_in_path, params: { email: user.email, password: user.password }.to_json,
                               headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
  end

  def get_auth_params_from_login_response_headers(response)
    client = response.headers['client']
    token = response.headers['access-token']
    expiry = response.headers['expiry']
    token_type = response.headers['token-type']
    uid = response.headers['uid']

    {
      'access-token' => token,
      'client' => client,
      'uid' => uid,
      'expiry' => expiry,
      'token-type' => token_type
    }
  end

  def add_param_avatar(params, filename)
    avatar64 = Base64.encode64(IO.read("spec/fixtures/#{filename}"))
    params[:avatar] =
      { data: "data:image/jpeg;base64,#{avatar64}",
        filename: filename }
    params
  end
end
