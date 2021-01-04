require 'rails_helper'

RSpec.describe 'Notes', type: :request do
  include JsonSupport

  let(:user) { FactoryBot.create(:user, :user_with_projects) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:folder) { FactoryBot.create(:folder, project: user.projects[0]) }
  let(:note) { FactoryBot.create(:note, project: user.projects[0], folder: folder) }
  let(:user_dummy) { FactoryBot.create(:user, :user_with_projects) }
  let(:folder_dummy) { FactoryBot.create(:folder, project: user_dummy.projects[0]) }
  let(:note_dummy) { FactoryBot.create(:note, project: user_dummy.projects[0], folder: folder_dummy) }

  describe 'GET #index' do
    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_folder_notes_path(
        project_id: user.projects[0].id,
        folder_id: note.folder.id
      ), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      let!(:note2) { FactoryBot.create(:note, project: user.projects[0], folder: folder) }

      it 'ユーザーが所属しているプロジェクトの場合、ノートが取得できる（複数）' do
        get v1_project_folder_notes_path(
          project_id: user.projects[0].id,
          folder_id: note.folder.id
        ), headers: auth_headers
        expect(json_parse_body(response).map { |note| note[:id] }).to eq folder.notes.ids
        expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
      end

      it 'ユーザーが所属していないプロジェクトの場合、ノートは取得できない' do
        get v1_project_folder_notes_path(
          project_id: user_dummy.projects[0].id,
          folder_id: note_dummy.folder.id
        ), headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it 'フォルダIDが存在しない場合、ノートは取得できない' do
        get v1_project_folder_notes_path(
          project_id: user.projects[0].id,
          folder_id: -1
        ), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_folder_note_path(
        project_id: user.projects[0].id,
        folder_id: note.folder.id,
        id: note.id
      ), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      it 'ユーザーが所属しているプロジェクトの場合、ノートが取得できる' do
        get v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: note.folder.id,
          id: note.id
        ), headers: auth_headers
        expect(json_parse_body(response)[:id]).to eq note.id
      end

      it 'ユーザーが所属していないプロジェクトの場合、ノートは取得できない' do
        get v1_project_folder_note_path(
          project_id: user_dummy.projects[0].id,
          folder_id: note_dummy.folder.id,
          id: note_dummy.id
        ), headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it 'ノートIDが存在しない場合、ノートは取得できない' do
        get v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: note.folder.id,
          id: -1
        ), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it 'フォルダIDが存在しない場合、ノートは取得できない' do
        get v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: -1,
          id: note.id
        ), headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:note_attributes) { FactoryBot.attributes_for(:note) }

    it '認証されていない場合は作成できない' do
      auth_headers['access-token'] = '12345'
      expect do
        post v1_project_folder_notes_path(
          project_id: user.projects[0].id,
          folder_id: folder.id
        ), params: { note: note_attributes },
           headers: auth_headers
      end.to change(folder.notes, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      it 'ユーザーが所属しているプロジェクトの場合、ノートが作成できる' do
        expect do
          post v1_project_folder_notes_path(
            project_id: user.projects[0].id,
            folder_id: folder.id
          ), params: { note: note_attributes },
             headers: auth_headers
        end.to change(folder.notes, :count).by(1)
      end

      it 'ユーザーが所属していないプロジェクトの場合、ノートは作成できない' do
        expect do
          post v1_project_folder_notes_path(
            project_id: user_dummy.projects[0].id,
            folder_id: folder_dummy.id
          ), params: { note: note_attributes },
             headers: auth_headers
        end.to change(folder.notes, :count).by(0)
        expect(response).to have_http_status(:forbidden)
      end

      it 'フォルダIDが存在しない場合、ノートは作成できない' do
        expect do
          post v1_project_folder_notes_path(
            project_id: user.projects[0].id,
            folder_id: -1
          ), params: { note: note_attributes },
             headers: auth_headers
        end.to change(folder.notes, :count).by(0)
        expect(response).to have_http_status(:not_found)
      end

      # Dummy Comment For Formatter Error
      context 'パラメータが異常値の場合' do
        it '作成できない' do
          expect do
            post v1_project_folder_notes_path(
              project_id: user.projects[0].id,
              folder_id: folder.id
            ), params: { test: 'test' },
               headers: auth_headers
          end.to change(folder.notes, :count).by(0)
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:note2_attributes) { FactoryBot.attributes_for(:note2) }

    it '認証されていない場合は更新できない' do
      auth_headers['access-token'] = '12345'
      put v1_project_folder_note_path(
        project_id: user.projects[0].id,
        folder_id: folder.id,
        id: note.id
      ), params: { note: note2_attributes },
         headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      it 'ユーザーが所属しているプロジェクトの場合、ノートが更新できる' do
        put v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: folder.id,
          id: note.id
        ), params: { note: note2_attributes },
           headers: auth_headers
        expect(response.status).to eq(200)
        expect(json_parse_body(response)[:title]).to eq(note2_attributes[:title])
      end

      it 'ユーザーが所属していないプロジェクトの場合、ノートは更新できない' do
        put v1_project_folder_note_path(
          project_id: user_dummy.projects[0].id,
          folder_id: folder_dummy.id,
          id: note_dummy.id
        ), params: { note: note2_attributes },
           headers: auth_headers
        expect(response).to have_http_status(:forbidden)
        expect(json_parse_body(response)[:title]).not_to eq(note2_attributes[:title])
      end

      it 'フォルダIDが存在しない場合、ノートは更新できない' do
        put v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: -1,
          id: note.id
        ), params: { note: note2_attributes },
           headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      context 'パラメーターが異常値の場合' do
        it '更新できない' do
          put v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: folder.id,
            id: note.id
          ), params: { test: 'test' },
             headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'パラメーターにlock_versionが存在しない場合は更新できない' do
          note2_attributes.reject! { |k| k == :lock_version }
          put v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: folder.id,
            id: note.id
          ), params: { note: note2_attributes },
             headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it 'DBのlock_versionと更新対象のlock_versonが存在しない場合は更新できない' do
          note2_attributes[:lock_version] = -1
          put v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: folder.id,
            id: note.id
          ), params: { note: note2_attributes },
             headers: auth_headers
          expect(response).to have_http_status(:conflict)
        end

        it '存在しないノートIDの場合は更新できない' do
          put v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: folder.id,
            id: -1
          ), params: { note: note2_attributes },
             headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE #delete' do
    # expect内で作成しないよう、事前に作成しておく
    let!(:note) { FactoryBot.create(:note, project: user.projects[0], folder: folder) }
    let!(:note_dummy) { FactoryBot.create(:note, project: user_dummy.projects[0], folder: folder_dummy) }

    it '認証されていない場合は削除できない' do
      auth_headers['access-token'] = '12345'
      expect do
        delete v1_project_folder_note_path(
          project_id: user.projects[0].id,
          folder_id: folder.id,
          id: note.id
        ), headers: auth_headers
      end.to change(folder.notes, :count).by(0)
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      it 'ユーザーが所属するプロジェクトの場合はノートを削除できる' do
        expect do
          delete v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: folder.id,
            id: note.id
          ), headers: auth_headers
        end.to change(folder.notes, :count).by(-1)
        expect(response.status).to eq(200)
      end

      it 'ユーザーが所属しないプロジェクトの場合はノートを削除できない' do
        expect do
          delete v1_project_folder_note_path(
            project_id: user_dummy.projects[0].id,
            folder_id: folder_dummy.id,
            id: note_dummy.id
          ), headers: auth_headers
        end.to change(folder.notes, :count).by(0)
        expect(response.status).to eq(403)
      end

      it 'フォルダIDが存在しない場合、ノートは削除できない' do
        expect do
          delete v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: -1,
            id: note.id
          ), headers: auth_headers
        end.to change(folder.notes, :count).by(0)
        expect(response).to have_http_status(:not_found)
      end

      context 'パラメーターが異常値の場合' do
        it '存在しないIDの場合は、削除できない' do
          expect do
            delete v1_project_folder_note_path(
              project_id: user.projects[0].id,
              folder_id: folder.id,
              id: -1
            ), headers: auth_headers
          end.to change(folder.notes, :count).by(0)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
