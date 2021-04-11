# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Folders', type: :request do
  include JsonSupport

  let(:user) { FactoryBot.create(:user, :user_with_projects) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:folder) { FactoryBot.create(:folder, project: user.projects[0]) }
  let!(:user_dummy) { FactoryBot.create(:user, :user_with_projects) } # 比較用として最初に作成する
  let!(:folder_dummy) { FactoryBot.create(:folder, project: user_dummy.projects[0]) } # 比較用として最初に作成する

  describe 'GET #index' do
    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_folders_path(project_id: folder.project.id), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      let!(:folder2) { FactoryBot.create(:folder, project: user.projects[0]) }

      it 'ユーザーが所属しているプロジェクトの場合、フォルダが取得できる(複数)' do
        get v1_project_folders_path(project_id: folder.project.id), headers: auth_headers
        expect(json_parse_body(response).map { |folder| folder[:id] }).to eq user.projects[0].folders.ids
        expect(json_parse_body(response).map { |folder| folder[:id] }.length).to eq 2
      end

      it 'ユーザーが所属していないプロジェクトの場合、フォルダは所得できない' do
        get v1_project_folders_path(project_id: folder_dummy.project.id), headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #show' do
    it '認証がされていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_folder_path(project_id: folder.project.id, id: folder.id), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属しているプロジェクトのデータは取得できない' do
        get v1_project_folder_path(project_id: folder.project.id, id: folder.id), headers: auth_headers
        expect(json_parse_body(response)[:id]).to eq folder.id
      end

      it 'ユーザーが所属していないプロジェクトのデータは取得できない' do
        get v1_project_folder_path(project_id: folder_dummy.project.id, id: folder_dummy.id), headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it '存在しないIDの場合は、取得できない' do
        get v1_project_folder_path(project_id: folder.project.id, id: -1), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:folder_attributes) { FactoryBot.attributes_for(:folder) }

    it '認証されていない場合は作成できない' do
      expect do
        auth_headers['access-token'] = '12345'
        post v1_project_folders_path(project_id: user.projects[0].id), params: { folder: folder_attributes },
                                                                       headers: auth_headers
      end.to change(folder.notes, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属しているプロジェクトの場合、フォルダが作成できる' do
        expect do
          post v1_project_folders_path(project_id: user.projects[0].id), params: { folder: folder_attributes },
                                                                         headers: auth_headers
        end.to change(user.projects[0].folders, :count).by(1)
      end

      it 'ユーザーが所属していないプロジェクトの場合、フォルダは作成できない' do
        expect do
          post v1_project_folders_path(project_id: user_dummy.projects[0].id), params: { folder: folder_attributes },
                                                                               headers: auth_headers
        end.to change(user.projects[0].folders, :count).by(0)
        expect(response.status).to eq(403)
      end

      context 'when パラメーターが異常値' do
        it '作成できない' do
          expect do
            post v1_project_folders_path(project_id: user.projects[0].id), params: { test: 'test' },
                                                                           headers: auth_headers
          end.to change(folder.notes, :count).by(0)
          expect(response).to have_http_status(:bad_request)
        end

        it 'nameが存在しない場合は作成できない' do
          folder_attributes.reject! { |k| k == :name }
          expect do
            post v1_project_folders_path(project_id: user.projects[0].id), params: { folder: folder_attributes },
                                                                           headers: auth_headers
          end.to change(folder.notes, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:folder2_attributes) { FactoryBot.attributes_for(:folder2) }

    it '認証されていない場合は更新できない' do
      auth_headers['access-token'] = '12345'
      put v1_project_folder_path(project_id: folder.project.id, id: folder.id),
          params: { folder: folder2_attributes }, headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属するプロジェクトの場合は更新できる' do
        put v1_project_folder_path(project_id: folder.project.id, id: folder.id),
            params: { folder: folder2_attributes }, headers: auth_headers
        expect(response.status).to eq(200)
        expect(json_parse_body(response)[:name]).to eq(folder2_attributes[:name])
      end

      it 'ユーザーが所属しないプロジェクトの場合は更新できない' do
        put v1_project_folder_path(project_id: user_dummy.projects[0].id, id: folder_dummy.id),
            params: { folder: folder2_attributes }, headers: auth_headers
        expect(response.status).to eq(403)
        expect(json_parse_body(response)[:name]).not_to eq(folder2_attributes[:name])
      end

      context 'when パラメーターが異常値' do
        it '更新できない' do
          put v1_project_folder_path(project_id: folder.project.id, id: folder.id), params: { test: 'test' },
                                                                                    headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'nameがNULLの場合は更新できない' do
          folder2_attributes[:name] = nil
          put v1_project_folder_path(project_id: folder.project.id, id: folder.id),
              params: { folder: folder2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'パラメーターにlock_versionが存在しない場合は更新できない' do
          folder2_attributes.reject! { |k| k == :lock_version }
          put v1_project_folder_path(project_id: folder.project.id, id: folder.id),
              params: { folder: folder2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'DBのlock_versionと更新対象のlock_versionが異なる場合は更新できない' do
          folder2_attributes[:lock_version] = -1
          put v1_project_folder_path(project_id: folder.project.id, id: folder.id),
              params: { folder: folder2_attributes }, headers: auth_headers
          expect(response).to have_http_status(:conflict)
        end

        it '存在しないIDの場合は、更新できない' do
          put v1_project_folder_path(project_id: folder.project.id, id: -1), params: { folder: folder2_attributes },
                                                                             headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE #delete' do
    # expect内で作成しないよう、事前に作成しておく
    let!(:folder) { FactoryBot.create(:folder, project: user.projects[0]) }
    let!(:folder_dummy) { FactoryBot.create(:folder, project: user_dummy.projects[0]) }

    it '認証されていない場合は削除できない' do
      auth_headers['access-token'] = '12345'
      expect do
        delete v1_project_folder_path(project_id: folder.project.id, id: folder.id), headers: auth_headers
      end.to change(user.projects[0].folders, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when 認証されている' do
      it 'ユーザーが所属するプロジェクトの場合はフォルダを削除できる' do
        expect do
          delete v1_project_folder_path(project_id: folder.project.id, id: folder.id), headers: auth_headers
        end.to change(user.projects[0].folders, :count).by(-1)
        expect(response.status).to eq(200)
      end

      it 'ユーザーが所属しないプロジェクトの場合はフォルダを削除できない' do
        expect do
          delete v1_project_folder_path(project_id: folder_dummy.project.id, id: folder_dummy.id), headers: auth_headers
        end.to change(user.projects[0].folders, :count).by(0)
        expect(response.status).to eq(403)
      end

      context 'when パラメーターが異常値' do
        it '存在しないIDの場合は、削除できない' do
          expect do
            delete v1_project_folder_path(project_id: folder.project.id, id: -1), headers: auth_headers
          end.to change(user.projects[0].folders, :count).by(0)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
