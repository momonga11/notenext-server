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

      context 'when プロジェクトにユーザーが所属している' do
        subject :get_folders do
          get v1_project_folders_path(project_id: folder.project.id), headers: auth_headers
          response
        end

        it 'フォルダが取得できる(複数)' do
          expect(get_folders).to have_http_status(:ok)
          expect(json_parse_body(response).map { |folder| folder[:id] }).to eq user.projects[0].folders.ids
          expect(json_parse_body(response).map { |folder| folder[:id] }.length).to eq 2
        end

        context 'when task is exists' do
          before do
            FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
            FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
            FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder2))
          end

          it 'タスクの件数が取得できる' do
            expect(get_folders).to have_http_status(:ok)
            expect(json_parse_body(response).map { |folder| folder[:tasks_count] }).to include 1, 2
          end
        end
      end

      it 'ユーザーが所属していないプロジェクトの場合、フォルダは所得できない' do
        get v1_project_folders_path(project_id: folder_dummy.project.id), headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      context 'when params note' do
        subject :get_folders_with_note do
          get v1_project_folders_path(project_id: folder.project.id), params: { note: true }, headers: auth_headers
          response
        end

        let!(:folder2) { FactoryBot.create(:folder2, project: user.projects[0]) }
        let!(:note) { FactoryBot.create(:note, project: user.projects[0], folder: folder2) }

        it 'ノートが紐づくフォルダのみ取得できる' do
          folders = json_parse_body(get_folders_with_note).map { |folder| folder[:id] }
          expect(folders).to include folder2.id
          expect(folders).not_to include folder.id
        end

        context 'when task is exists' do
          before do
            FactoryBot.create(:task, note: note)
          end

          it 'タスクの件数が取得できる' do
            expect(get_folders_with_note).to have_http_status(:ok)
            expect(json_parse_body(response).map { |folder| folder[:tasks_count] }[0]).to eq 1
          end
        end

        context 'when params note and search' do
          subject :get_folders_with_note_search do
            get v1_project_folders_path(project_id: folder.project.id), params: { note: true, search: search },
                                                                        headers: auth_headers
            response
          end

          let!(:folder3) { FactoryBot.create(:folder2, project: user.projects[0]) }
          let!(:note2) { FactoryBot.create(:note2, project: user.projects[0], folder: folder3) }
          let(:search) { '田舎' }

          it 'params:search の条件に該当するノートが紐づくフォルダのみ取得できる' do
            folders = json_parse_body(get_folders_with_note_search).map { |folder| folder[:id] }
            expect(folders).to include folder3.id
            expect(folders).not_to include folder.id, folder2.id
          end

          context 'when task is exists' do
            before do
              FactoryBot.create(:task, note: note2)
            end

            it 'タスクの件数が取得できる' do
              expect(get_folders_with_note_search).to have_http_status(:ok)
              expect(json_parse_body(response).map { |folder| folder[:tasks_count] }[0]).to eq 1
            end
          end
        end
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
      context 'when プロジェクトにユーザーが所属している' do
        subject :get_folder do
          get v1_project_folder_path(project_id: folder.project.id, id: folder.id), headers: auth_headers
          response
        end

        it 'ユーザーが所属しているプロジェクトのデータは取得できる' do
          expect(json_parse_body(get_folder)[:id]).to eq folder.id
        end

        context 'when task is exists' do
          before do
            FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
          end

          it 'タスクの件数が取得できる' do
            expect(get_folder).to have_http_status(:ok)
            expect(json_parse_body(response)[:tasks_count]).to eq 1
          end
        end
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
