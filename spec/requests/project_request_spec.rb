# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  include JsonSupport

  let(:user) { FactoryBot.create(:user, :user_with_projects) }
  let(:auth_headers) { user.create_new_auth_token }
  let!(:user2) { FactoryBot.create(:user, :user_with_projects) } # user2は比較用として最初に作成する

  describe 'GET #index' do
    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_projects_path, headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属しているプロジェクトのデータが取得できる' do
        get v1_projects_path, headers: auth_headers
        expect(json_parse_body(response).map { |project| project[:id] }).to eq user.projects.ids
      end
    end
  end

  describe 'GET #show' do
    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_path(user.projects.ids[0]), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      context 'when クエリパラメーターにwith_associationが存在する' do
        context 'when with_association=True' do
          subject :get_projects_with_association do
            get v1_project_path(user.projects.ids[0]), params: { with_association: true }, headers: auth_headers
            response
          end

          it 'ユーザーが所属しているヘッダー用プロジェクトのデータは取得できる' do
            response_json = json_parse_body(get_projects_with_association)
            expect(response_json[:id]).to eq user.projects.ids[0]
            # response.bodyの検証
            expect(response_json).to be_key(:name)
            expect(response_json).to be_key(:user)
            expect(response_json[:user]).to be_key(:avatar)
            expect(response_json).to be_key(:folders)
          end

          context 'when task is exists' do
            let(:folder) { FactoryBot.create(:folder, project: user.projects[0]) }
            let(:note) { FactoryBot.create(:note, folder: folder) }

            before do
              FactoryBot.create(:task, note: note)
            end

            it 'タスクの件数が取得できる' do
              expect(get_projects_with_association).to have_http_status(:ok)
              expect(json_parse_body(response)[:folders][0][:tasks_count]).to eq 1
            end
          end

          it 'ユーザーが所属していないヘッダー用プロジェクトのデータは取得できない' do
            get v1_project_path(user2.projects.ids[0]), params: { with_association: true }, headers: auth_headers
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'when with_association=False' do
          it 'ユーザーが所属しているプロジェクトのデータは取得できる' do
            get v1_project_path(user.projects.ids[0]), params: { with_association: false }, headers: auth_headers
            expect(json_parse_body(response)[:id]).to eq user.projects.ids[0]
          end

          it 'ユーザーが所属していないプロジェクトのデータは取得できない' do
            get v1_project_path(user2.projects.ids[0]), params: { with_association: false }, headers: auth_headers
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'when クエリパラメーターにwith_associationが存在しない' do
        it 'ユーザーが所属しているプロジェクトのデータは取得できる' do
          get v1_project_path(user.projects.ids[0]), headers: auth_headers
          expect(json_parse_body(response)[:id]).to eq user.projects.ids[0]
        end

        it 'ユーザーが所属していないプロジェクトは取得できない' do
          get v1_project_path(user2.projects.ids[0]), headers: auth_headers
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    let(:project_attributes) { FactoryBot.attributes_for(:project) }

    it '認証されていない場合は作成できない' do
      expect do
        auth_headers['access-token'] = '12345'
        post v1_projects_path, params: { project: project_attributes }, headers: auth_headers
      end.to change(user.projects, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーがオーナーのプロジェクトが一つもない場合は作成できる' do
        expect do
          post v1_projects_path, params: { project: project_attributes }, headers: auth_headers
        end.to change(user.projects, :count).by(1)
      end

      it 'ユーザーがオーナーのプロジェクトが一つ以上ある場合は作成できない' do
        expect do
          post v1_projects_path, params: { project: project_attributes }, headers: auth_headers
        end.to change(user.projects, :count).by(1)
        post v1_projects_path, params: { project: project_attributes }, headers: auth_headers
        expect(response.body).to include('ユーザーが作成できるプロジェクト数の上限を越えているため、作成できません。')
      end

      context 'when パラメーターが異常値' do
        it '作成できない' do
          expect do
            post v1_projects_path, params: { test: 'test' }, headers: auth_headers
          end.to change(user.projects, :count).by(0)
          expect(response).to have_http_status(:bad_request)
        end

        it 'nameが存在しない場合は作成できない' do
          project_attributes.reject! { |k| k == :name }
          expect do
            post v1_projects_path, params: { project: project_attributes }, headers: auth_headers
          end.to change(user.projects, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:project2_attributes) { FactoryBot.attributes_for(:project2) }

    it '認証されていない場合は更新できない' do
      auth_headers['access-token'] = '12345'
      put v1_project_path(user.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されていない' do
      it 'ユーザーが所属するプロジェクトの場合は更新できる' do
        put v1_project_path(user.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
        response_json = json_parse_body(response)
        expect(response.status).to eq(200)
        expect(response_json[:name]).to eq(project2_attributes[:name])
      end

      it 'ユーザーが所属しないプロジェクトの場合は更新できない' do
        put v1_project_path(user2.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
        response_json = json_parse_body(response)
        expect(response.status).to eq(403)
        expect(response_json[:name]).not_to eq(project2_attributes[:name])
      end

      context 'when パラメーターが異常値' do
        it '更新できない' do
          put v1_project_path(user.projects.ids[0]), params: { test: 'test' }, headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'nameがNULLの場合は更新できない' do
          project2_attributes[:name] = nil
          put v1_project_path(user.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'パラメーターにlock_versionが存在しない場合は更新できない' do
          project2_attributes.reject! { |k| k == :lock_version }
          put v1_project_path(user.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'DBのlock_versionと更新対象のlock_versionが異なる場合は更新できない' do
          project2_attributes[:lock_version] = -1
          put v1_project_path(user.projects.ids[0]), params: { project: project2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:conflict)
        end
      end
    end
  end

  describe 'DELETE #delete' do
    it '認証されていない場合は削除できない' do
      auth_headers['access-token'] = '12345'
      expect do
        delete v1_project_path(user.projects.ids[0]), headers: auth_headers
      end.to change(user.projects, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属するプロジェクトの場合は削除できる' do
        expect do
          delete v1_project_path(user.projects.ids[0]), headers: auth_headers
        end.to change(user.projects, :count).by(-1)
        expect(response.status).to eq(200)
      end

      it 'ユーザーが所属しないプロジェクトの場合は削除できない' do
        expect do
          delete v1_project_path(user2.projects.ids[0]), headers: auth_headers
        end.to change(user.projects, :count).by(0)
        expect(response.status).to eq(403)
      end

      context 'when パラメーターが異常値' do
        it '存在しないIDの場合は、削除できない' do
          expect do
            delete v1_project_path('test'), headers: auth_headers
          end.to change(user.projects, :count).by(0)
          expect(response.status).to eq(403)
        end
      end
    end
  end
end
