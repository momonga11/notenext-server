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

      context 'ユーザーが所属しているプロジェクトの場合' do
        context 'クエリパラメーターにwith_associationが存在する場合' do
          subject do
            get v1_project_folder_notes_path(
              project_id: user.projects[0].id,
              folder_id: folder_id
            ), params: { with_association: with_association }, headers: auth_headers
            response
          end

          context 'with_association=Trueの場合' do
            let(:with_association) { true }
            let(:folder_id) { note.folder.id }

            it 'ノート(複数)と紐づくフォルダ情報が取得できる' do
              expect(subject).to have_http_status(:ok)
              expect(json_parse_body(response)[:notes].map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response)[:notes].map { |note| note[:id] }.length).to eq 2
              expect(json_parse_body(response)[:id]).to eq folder.id
              expect(json_parse_body(response)[:name]).to eq folder.name
              expect(json_parse_body(response)[:description]).to eq folder.description
            end

            context 'フォルダIDが存在しない場合' do
              let(:folder_id) { -1 }

              it 'ノートは取得できない' do
                expect(subject).to have_http_status(:not_found)
              end
            end
          end

          context 'with_association=Falseの場合' do
            let(:with_association) { false }
            let(:folder_id) { note.folder.id }

            it 'ノートが取得できる(複数)' do
              expect(subject).to have_http_status(:ok)
              expect(json_parse_body(response).map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
            end

            context 'フォルダIDが存在しない場合' do
              let(:folder_id) { -1 }

              it 'ノートは取得できない' do
                expect(subject).to have_http_status(:not_found)
              end
            end
          end
        end

        context 'クエリパラメーターにwith_associationが存在しない場合' do
          subject do
            get v1_project_folder_notes_path(
              project_id: user.projects[0].id,
              folder_id: folder_id
            ), headers: auth_headers
            response
          end

          context 'フォルダIDが存在する場合' do
            let(:folder_id) { note.folder.id }

            it 'ノートが取得できる(複数)' do
              expect(subject).to have_http_status(:ok)
              expect(json_parse_body(response).map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
            end
          end

          context 'フォルダIDが存在しない場合' do
            let(:folder_id) { -1 }

            it 'ノートは取得できない' do
              expect(subject).to have_http_status(:not_found)
            end
          end
        end
      end

      context 'ユーザーが所属していないプロジェクトの場合、ノートは取得できない' do
        context 'クエリパラメーターにwith_associationが存在する場合' do
          it 'ノートは取得できない' do
            get v1_project_folder_notes_path(
              project_id: user_dummy.projects[0].id,
              folder_id: note_dummy.folder.id
            ), params: { with_association: true }, headers: auth_headers
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'クエリパラメーターにwith_associationが存在しない場合' do
          it 'ノートは取得できない' do
            get v1_project_folder_notes_path(
              project_id: user_dummy.projects[0].id,
              folder_id: note_dummy.folder.id
            ), headers: auth_headers
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end

  describe 'GET #all' do
    let!(:folder2) { FactoryBot.create(:folder, project: user.projects[0]) }
    let!(:note2) { FactoryBot.create(:note, project: user.projects[0], folder: folder2) }
    let!(:note_dummy) { FactoryBot.create(:note, project: user_dummy.projects[0], folder: folder_dummy) }

    it '認証されていない場合は取得できない' do
      auth_headers['access-token'] = '12345'
      get v1_project_notes_path(
        project_id: note.project_id
      ), headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      context 'ユーザーが所属しているプロジェクトの場合' do
        it 'フォルダを跨いでノートが取得できる(複数)' do
          get v1_project_notes_path(
            project_id: note.project_id
          ), headers: auth_headers

          expect(response).to have_http_status(:ok)
          expect(json_parse_body(response).map { |note| note[:id] }).to eq(folder.notes.ids + folder2.notes.ids)
          expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
        end
      end
    end

    context 'ユーザーが所属していないプロジェクトの場合' do
      it 'ノートが取得できない' do
        get v1_project_notes_path(
          project_id: user_dummy.projects[0].id
        ), headers: auth_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #show' do
    describe 'フォルダIDを指定する' do
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
        it 'ユーザーが所属しているプロジェクトの場合はノートが取得できる' do
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

    describe 'フォルダIDを指定しない' do
      it '認証されていない場合は取得できない' do
        auth_headers['access-token'] = '12345'
        get v1_project_note_path(
          project_id: user.projects[0].id,
          id: note.id
        ), headers: auth_headers
        expect(response).to have_http_status(:unauthorized)
      end

      context '認証されている場合' do
        it 'ユーザ-が所属さているプロジェクトの場合はノートが取得でする' do
          get v1_project_note_path(
            project_id: user.projects[0].id,
            id: note.id
          ), headers: auth_headers
          expect(json_parse_body(response)[:id]).to eq note.id
        end

        it 'ユーザーが所属していないプロジェクトの場合、ノートは取得できない' do
          get v1_project_note_path(
            project_id: user_dummy.projects[0].id,
            id: note_dummy.id
          ), headers: auth_headers
          expect(response).to have_http_status(:forbidden)
        end

        it 'ノートIDが存在しない場合、ノートは取得できない' do
          get v1_project_note_path(
            project_id: user.projects[0].id,
            id: -1
          ), headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
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
      context 'ユーザーが所属するプロジェクトの場合' do
        it 'ノートを削除できる' do
          expect do
            delete v1_project_folder_note_path(
              project_id: user.projects[0].id,
              folder_id: folder.id,
              id: note.id
            ), headers: auth_headers
          end.to change(folder.notes, :count).by(-1)
          expect(response.status).to eq(200)
        end

        context '画像ファイルが添付されていた場合' do
          let(:image_attribute) do
            image_encoded = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
            { data: "data:image/jpeg;base64,#{image_encoded}", filename: 'neko_test.jpg' }
          end

          before do
            put v1_project_note_image_attach_path(
              project_id: user.projects[0].id,
              id: note.id
            ), params: { note: { lock_version: note.lock_version, images: image_attribute } },
               headers: auth_headers
          end

          it 'ノートを削除すると画像ファイルも削除される' do
            expect(note.images.attached?).to be_truthy
            expect do
              delete v1_project_folder_note_path(
                project_id: user.projects[0].id,
                folder_id: folder.id,
                id: note.id
              ), headers: auth_headers
            end.to change(folder.notes, :count).by(-1)

            expect(response.status).to eq(200)
            expect(note.images.attached?).to be_falsey
          end
        end
      end

      it 'ユーザーが所属しているプロジェクトの場合はノートを削除できない' do
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

  describe 'PUT #attach_image' do
    let(:image_attribute) do
      image_encoded = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
      { data: "data:image/jpeg;base64,#{image_encoded}", filename: 'neko_test.jpg' }
    end

    it '認証されていない場合は更新できない' do
      auth_headers['access-token'] = '12345'
      put v1_project_note_image_attach_path(
        project_id: user.projects[0].id,
        id: note.id
      ), params: { note: { lock_version: note.lock_version, images: image_attribute } },
         headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context '認証されている場合' do
      context 'ユーザーが所属しているプロジェクトの場合' do
        it '画像を追加できる' do
          put v1_project_note_image_attach_path(
            project_id: user.projects[0].id,
            id: note.id
          ), params: { note: { lock_version: note.lock_version, images: image_attribute } },
             headers: auth_headers

          expect(response.status).to eq(200)
          expect(Note.find(note.id).images.attached?).to be_truthy
        end
      end

      context 'ユーザーが所属していないプロジェクトの場合' do
        it '画像を追加できない' do
          put v1_project_note_image_attach_path(
            project_id: user_dummy.projects[0].id,
            id: note_dummy.id
          ), params: { note: { lock_version: note_dummy.lock_version, images: image_attribute } },
             headers: auth_headers
          expect(response).to have_http_status(:forbidden)
          expect(Note.find(note_dummy.id).images.attached?).to be_falsey
        end
      end

      context 'パラメーターが異常値の場合' do
        it '更新できない' do
          put v1_project_note_image_attach_path(
            project_id: user.projects[0].id,
            id: note.id
          ), params: { test: 'test' },
             headers: auth_headers
          expect(response).to have_http_status(:bad_request)
        end

        it '存在しないノートIDの場合は更新できない' do
          put v1_project_note_image_attach_path(
            project_id: user.projects[0].id,
            id: -1
          ), params: { note: { lock_version: note.lock_version, images: image_attribute } },
             headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
