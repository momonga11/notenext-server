# frozen_string_literal: true

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

    context 'when 認証されている' do
      let!(:note2) { FactoryBot.create(:note2, project: user.projects[0], folder: folder) }

      context 'when ユーザーが所属しているプロジェクト' do
        context 'when クエリパラメーターにwith_associationが存在する' do
          subject :get_notes_with_association do
            get v1_project_folder_notes_path(
              project_id: user.projects[0].id,
              folder_id: folder_id
            ), params: { with_association: with_association }, headers: auth_headers
            response
          end

          context 'when with_association=True' do
            let(:with_association) { true }
            let(:folder_id) { note.folder.id }

            it 'ノート(複数)と紐づくフォルダ情報が取得できる' do
              expect(get_notes_with_association).to have_http_status(:ok)
              expect(json_parse_body(response)[:notes].map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response)[:notes].map { |note| note[:id] }.length).to eq 2
              expect(json_parse_body(response)[:id]).to eq folder.id
              expect(json_parse_body(response)[:name]).to eq folder.name
              expect(json_parse_body(response)[:description]).to eq folder.description
            end

            context 'with pagination' do
              subject :get_notes_with_association_and_paging do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page }, headers: auth_headers
                response
              end

              shared_examples 'get paging note' do |notes_index|
                it do
                  expect(get_notes_with_association_and_paging).to have_http_status(:ok)
                  expect(json_parse_body(response)[:notes].map { |note| note[:id] }[0]).to eq folder.notes[notes_index].id
                  expect(json_parse_body(response)[:notes].map { |note| note[:id] }.length).to eq 1
                end
              end

              before do
                @per_page = Kaminari.config.default_per_page
                Kaminari.config.default_per_page = 1
              end

              after do
                Kaminari.config.default_per_page = @per_page
              end

              context 'when page=1' do
                let(:page) { 1 }

                it_behaves_like 'get paging note', 0
              end

              context 'when page not 1' do
                let(:page) { 2 }

                it_behaves_like 'get paging note', 1
              end
            end

            context 'when sort by' do
              subject :get_notes_with_association_and_sort do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page, sort: sort }, headers: auth_headers
                response
              end

              let(:page) { 1 }

              context 'when sort asc' do
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteが取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response)[:notes].map { |note| note[:title] }
                  expect(titles[0]).to eq note.title
                  expect(titles[1]).to eq note2.title
                end
              end

              context 'when sort desc' do
                let(:sort) { 'title:desc' }

                it 'titleの降順に並んだNoteが取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response)[:notes].map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles[1]).to eq note.title
                end
              end

              describe 'default sort' do
                shared_examples 'dafault sort id:asc' do
                  it do
                    expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                    ids = json_parse_body(response)[:notes].map { |note| note[:id] }
                    expect(ids[0]).to eq note2.id
                    expect(ids[1]).to eq note.id
                  end
                end

                context 'when sort is nothing' do
                  let(:sort) { '' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is nothing' do
                  let(:sort) { ':asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is incorrect' do
                  let(:sort) { 'ida:asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is nothing' do
                  let(:sort) { 'ida' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order do not exist' do
                  let(:sort) { 'ida:' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is incorrect' do
                  let(:sort) { 'ida:asac' }

                  it_behaves_like 'dafault sort id:asc'
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteの2ページ目が取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response)[:notes].map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles.length).to eq 1
                end
              end
            end

            context 'when text search' do
              subject :get_notes_with_association_and_search do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page, sort: sort, search: search }, headers: auth_headers
                response
              end

              let!(:note3) { FactoryBot.create(:note3, project: user.projects[0], folder: folder) }
              let(:page) { 1 }
              let(:sort) { '' }

              context 'when title 部分一致' do
                let(:search) { 'NoteT' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response)[:notes].map { |note| note[:id] }
                  expect(note_ids).to include note3.id
                  expect(note_ids).not_to include note.id, note2.id
                end
              end

              context 'when text 部分一致' do
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response)[:notes].map { |note| note[:id] }
                  expect(note_ids).to include note2.id, note3.id
                  expect(note_ids).not_to include note.id
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:desc' }
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response)[:notes].map { |note| note[:id] }
                  expect(note_ids).to include note2.id
                  expect(note_ids).not_to include note.id, note3.id
                end

                context 'when task is exists' do
                  let!(:task) { FactoryBot.create(:task, note: note2) }

                  it 'タスク情報が取得できる' do
                    expect(get_notes_with_association_and_search).to have_http_status(:ok)
                    response_task = json_parse_body(response)[:notes][0][:task]
                    expect(response_task[:id]).to eq task.id
                    expect(Date.parse(response_task[:date_to])).to eq task.date_to
                    expect(response_task[:completed]).to eq task.completed
                  end
                end
              end
            end

            context 'when フォルダIDが存在しない' do
              let(:folder_id) { -1 }

              it 'ノートは取得できない' do
                expect(get_notes_with_association).to have_http_status(:not_found)
              end
            end
          end

          context 'when with_association=Falseの場合' do
            let(:with_association) { false }
            let(:folder_id) { note.folder.id }

            it 'ノートが取得できる(複数)' do
              expect(get_notes_with_association).to have_http_status(:ok)
              expect(json_parse_body(response).map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
            end

            context 'with pagination' do
              subject :get_notes_paging do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page }, headers: auth_headers
                response
              end

              shared_examples 'get paging note' do |notes_index|
                it do
                  expect(get_notes_paging).to have_http_status(:ok)
                  expect(json_parse_body(response)[0][:id]).to eq folder.notes[notes_index].id
                  expect(json_parse_body(response).length).to eq 1
                end
              end

              before do
                @per_page = Kaminari.config.default_per_page
                Kaminari.config.default_per_page = 1
              end

              after do
                Kaminari.config.default_per_page = @per_page
              end

              context 'when page=1' do
                let(:page) { 1 }

                it_behaves_like 'get paging note', 0
              end

              context 'when page not 1' do
                let(:page) { 2 }

                it_behaves_like 'get paging note', 1
              end
            end

            context 'when sort by' do
              subject :get_notes_with_association_and_sort do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page, sort: sort }, headers: auth_headers
                response
              end

              let(:page) { 1 }

              context 'when sort asc' do
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteが取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note.title
                  expect(titles[1]).to eq note2.title
                end
              end

              context 'when sort desc' do
                let(:sort) { 'title:desc' }

                it 'titleの降順に並んだNoteが取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles[1]).to eq note.title
                end
              end

              describe 'default sort' do
                shared_examples 'dafault sort id:asc' do
                  it do
                    expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                    ids = json_parse_body(response).map { |note| note[:id] }
                    expect(ids[0]).to eq note2.id
                    expect(ids[1]).to eq note.id
                  end
                end

                context 'when sort is nothing' do
                  let(:sort) { '' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is nothing' do
                  let(:sort) { ':asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is incorrect' do
                  let(:sort) { 'ida:asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is nothing' do
                  let(:sort) { 'ida' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order do not exist' do
                  let(:sort) { 'ida:' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is incorrect' do
                  let(:sort) { 'ida:asac' }

                  it_behaves_like 'dafault sort id:asc'
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteの2ページ目が取得できる' do
                  expect(get_notes_with_association_and_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles.length).to eq 1
                end
              end
            end

            context 'when text search' do
              subject :get_notes_with_association_and_search do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { with_association: with_association, page: page, sort: sort, search: search }, headers: auth_headers
                response
              end

              let!(:note3) { FactoryBot.create(:note3, project: user.projects[0], folder: folder) }
              let(:page) { 1 }
              let(:sort) { '' }

              context 'when title 部分一致' do
                let(:search) { 'NoteT' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note3.id
                  expect(note_ids).not_to include note.id, note2.id
                end
              end

              context 'when text 部分一致' do
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note2.id, note3.id
                  expect(note_ids).not_to include note.id
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:desc' }
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note2.id
                  expect(note_ids).not_to include note.id, note3.id
                end

                context 'when task is exists' do
                  let!(:task) { FactoryBot.create(:task, note: note2) }

                  it 'タスク情報が取得できる' do
                    expect(get_notes_with_association_and_search).to have_http_status(:ok)
                    response_task = json_parse_body(response)[0][:task]
                    expect(response_task[:id]).to eq task.id
                    expect(Date.parse(response_task[:date_to])).to eq task.date_to
                    expect(response_task[:completed]).to eq task.completed
                  end
                end
              end
            end

            context 'when フォルダIDが存在しない場合' do
              let(:folder_id) { -1 }

              it 'ノートは取得できない' do
                expect(get_notes_with_association).to have_http_status(:not_found)
              end
            end
          end
        end

        context 'when クエリパラメーターにwith_associationが存在しない' do
          subject(:get_notes) do
            get v1_project_folder_notes_path(
              project_id: user.projects[0].id,
              folder_id: folder_id
            ), headers: auth_headers
            response
          end

          context 'when フォルダIDが存在する' do
            let(:folder_id) { note.folder.id }

            it 'ノートが取得できる(複数)' do
              expect(get_notes).to have_http_status(:ok)
              expect(json_parse_body(response).map { |note| note[:id] }).to eq folder.notes.ids
              expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
            end

            context 'with pagination' do
              subject :get_notes_paging do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { page: page }, headers: auth_headers
                response
              end

              shared_examples 'get paging note' do |notes_index|
                it do
                  expect(get_notes_paging).to have_http_status(:ok)
                  expect(json_parse_body(response)[0][:id]).to eq folder.notes[notes_index].id
                  expect(json_parse_body(response).length).to eq 1
                end
              end

              before do
                @per_page = Kaminari.config.default_per_page
                Kaminari.config.default_per_page = 1
              end

              after do
                Kaminari.config.default_per_page = @per_page
              end

              context 'when page=1' do
                let(:page) { 1 }

                it_behaves_like 'get paging note', 0
              end

              context 'when page not 1' do
                let(:page) { 2 }

                it_behaves_like 'get paging note', 1
              end
            end

            context 'when sort by' do
              subject :get_notes_sort do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { page: page, sort: sort }, headers: auth_headers
                response
              end

              let(:page) { 1 }

              context 'when sort asc' do
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteが取得できる' do
                  expect(get_notes_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note.title
                  expect(titles[1]).to eq note2.title
                end
              end

              context 'when sort desc' do
                let(:sort) { 'title:desc' }

                it 'titleの降順に並んだNoteが取得できる' do
                  expect(get_notes_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles[1]).to eq note.title
                end
              end

              describe 'default sort' do
                shared_examples 'dafault sort id:asc' do
                  it do
                    expect(get_notes_sort).to have_http_status(:ok)
                    ids = json_parse_body(response).map { |note| note[:id] }
                    expect(ids[0]).to eq note2.id
                    expect(ids[1]).to eq note.id
                  end
                end

                context 'when sort is nothing' do
                  let(:sort) { '' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is nothing' do
                  let(:sort) { ':asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort column is incorrect' do
                  let(:sort) { 'ida:asc' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is nothing' do
                  let(:sort) { 'ida' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order do not exist' do
                  let(:sort) { 'ida:' }

                  it_behaves_like 'dafault sort id:asc'
                end

                context 'when sort order is incorrect' do
                  let(:sort) { 'ida:asac' }

                  it_behaves_like 'dafault sort id:asc'
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:asc' }

                it 'titleの昇順に並んだNoteの2ページ目が取得できる' do
                  expect(get_notes_sort).to have_http_status(:ok)
                  titles = json_parse_body(response).map { |note| note[:title] }
                  expect(titles[0]).to eq note2.title
                  expect(titles.length).to eq 1
                end
              end
            end

            context 'when text search' do
              subject :get_notes_with_association_and_search do
                get v1_project_folder_notes_path(
                  project_id: user.projects[0].id,
                  folder_id: folder_id
                ), params: { page: page, sort: sort, search: search }, headers: auth_headers
                response
              end

              let!(:note3) { FactoryBot.create(:note3, project: user.projects[0], folder: folder) }
              let(:page) { 1 }
              let(:sort) { '' }

              context 'when title 部分一致' do
                let(:search) { 'NoteT' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note3.id
                  expect(note_ids).not_to include note.id, note2.id
                end
              end

              context 'when text 部分一致' do
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note2.id, note3.id
                  expect(note_ids).not_to include note.id
                end
              end

              context 'when sort and pagination' do
                before do
                  @per_page = Kaminari.config.default_per_page
                  Kaminari.config.default_per_page = 1
                end

                after do
                  Kaminari.config.default_per_page = @per_page
                end

                let(:page) { 2 }
                let(:sort) { 'title:desc' }
                let(:search) { '田舎' }

                it '部分一致検索できること' do
                  expect(get_notes_with_association_and_search).to have_http_status(:ok)
                  note_ids = json_parse_body(response).map { |note| note[:id] }
                  expect(note_ids).to include note2.id
                  expect(note_ids).not_to include note.id, note3.id
                end
              end
            end
          end

          context 'when フォルダIDが存在しない場合' do
            let(:folder_id) { -1 }

            it 'ノートは取得できない' do
              expect(get_notes).to have_http_status(:not_found)
            end
          end
        end
      end

      context 'when ユーザーが所属していないプロジェクトの' do
        context 'when クエリパラメーターにwith_associationが存在する' do
          it 'ノートは取得できない' do
            get v1_project_folder_notes_path(
              project_id: user_dummy.projects[0].id,
              folder_id: note_dummy.folder.id
            ), params: { with_association: true }, headers: auth_headers
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'when クエリパラメーターにwith_associationが存在しない' do
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

    context 'when 認証されている' do
      context 'when ユーザーが所属しているプロジェクト' do
        subject :get_notes do
          get v1_project_notes_path(
            project_id: note.project_id
          ), headers: auth_headers
          response
        end

        it 'フォルダを跨いでノートが取得できる(複数)' do
          expect(get_notes).to have_http_status(:ok)
          expect(json_parse_body(response).map { |note| note[:id] }).to eq(folder.notes.ids + folder2.notes.ids)
          expect(json_parse_body(response).map { |note| note[:id] }.length).to eq 2
        end

        context 'when task is exists' do
          let!(:task) { FactoryBot.create(:task, note: note2) }

          it 'タスク情報が取得できる' do
            expect(get_notes).to have_http_status(:ok)
            response_task = json_parse_body(response).select { |note| note[:id] == note2.id }[0][:task]
            expect(response_task[:id]).to eq task.id
            expect(Date.parse(response_task[:date_to])).to eq task.date_to
            expect(response_task[:completed]).to eq task.completed
          end
        end

        context 'with pagination' do
          subject :get_notes_paging do
            get v1_project_notes_path(
              project_id: note.project_id
            ), params: { page: page }, headers: auth_headers
            response
          end

          shared_examples 'get paging note' do |_notes_index|
            it do
              expect(get_notes_paging).to have_http_status(:ok)
              expect(json_parse_body(response).length).to eq 1
            end
          end

          before do
            @per_page = Kaminari.config.default_per_page
            Kaminari.config.default_per_page = 1
          end

          after do
            Kaminari.config.default_per_page = @per_page
          end

          context 'when page=1' do
            let(:page) { 1 }

            it_behaves_like 'get paging note', 0
            it '1ページ目のノートが取得できること' do
              expect(get_notes_paging).to have_http_status(:ok)
              expect(json_parse_body(response)[0][:id]).to eq folder.notes[0].id
            end
          end

          context 'when page not 1' do
            let(:page) { 2 }

            it_behaves_like 'get paging note', 1
            it '2ページ目のノートが取得できること' do
              expect(get_notes_paging).to have_http_status(:ok)
              expect(json_parse_body(response)[0][:id]).to eq folder2.notes[0].id
            end
          end
        end

        context 'when text search' do
          subject :get_notes_all_page_and_search do
            get v1_project_notes_path(
              project_id: note.project_id
            ), params: { page: page, search: search }, headers: auth_headers
            response
          end

          let!(:folder3) { FactoryBot.create(:folder, project: user.projects[0]) }
          let!(:note3) { FactoryBot.create(:note3, project: user.projects[0], folder: folder3) }
          let(:page) { 1 }

          context 'when title 部分一致' do
            let(:search) { 'NoteT' }

            it '部分一致検索できること' do
              expect(get_notes_all_page_and_search).to have_http_status(:ok)
              note_ids = json_parse_body(response).map { |note| note[:id] }
              expect(note_ids).to include folder3.notes[0].id
              expect(note_ids).not_to include folder.notes[0].id, folder2.notes[0].id
            end
          end

          context 'when text 部分一致' do
            let(:search) { '田舎' }

            it '部分一致検索できること' do
              expect(get_notes_all_page_and_search).to have_http_status(:ok)
              note_ids = json_parse_body(response).map { |note| note[:id] }
              expect(note_ids).to include folder3.notes[0].id
              expect(note_ids).not_to include folder.notes[0].id, folder2.notes[0].id
            end
          end

          context 'when pagination' do
            before do
              @per_page = Kaminari.config.default_per_page
              Kaminari.config.default_per_page = 1
            end

            after do
              Kaminari.config.default_per_page = @per_page
            end

            let(:page) { 2 }
            let(:search) { '生涯' }

            it '部分一致検索できること' do
              expect(get_notes_all_page_and_search).to have_http_status(:ok)
              note_ids = json_parse_body(response).map { |note| note[:id] }
              expect(note_ids).to include folder2.notes[0].id
              expect(note_ids).not_to include folder.notes[0].id, folder3.notes[0].id
            end

            context 'when task is exists' do
              let!(:task) { FactoryBot.create(:task, note: note2) }

              it 'タスク情報が取得できる' do
                expect(get_notes_all_page_and_search).to have_http_status(:ok)
                response_task = json_parse_body(response).select { |note| note[:id] == note2.id }[0][:task]
                expect(response_task[:id]).to eq task.id
                expect(Date.parse(response_task[:date_to])).to eq task.date_to
                expect(response_task[:completed]).to eq task.completed
              end
            end
          end
        end
      end
    end

    context 'when ユーザーが所属していないプロジェクト' do
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

      context 'when 認証されている' do
        subject :get_note do
          get v1_project_folder_note_path(
            project_id: user.projects[0].id,
            folder_id: note.folder.id,
            id: note.id
          ), headers: auth_headers
          response
        end

        it 'ユーザーが所属しているプロジェクトの場合はノートが取得できる' do
          expect(json_parse_body(get_note)[:id]).to eq note.id
        end

        context 'when task is exists' do
          let!(:task) { FactoryBot.create(:task, note: note) }

          it 'タスク情報が取得できる' do
            expect(get_note).to have_http_status(:ok)
            response_task = json_parse_body(response)[:task]
            expect(response_task[:id]).to eq task.id
            expect(Date.parse(response_task[:date_to])).to eq task.date_to
            expect(response_task[:completed]).to eq task.completed
            expect(response_task[:lock_version]).to eq task.lock_version
          end
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

      context 'when 認証されている' do
        it 'ユーザ-が所属さているプロジェクトの場合、ノートが取得する' do
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

    context 'when 認証されている' do
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
      context 'when パラメータが異常値' do
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

    context 'when 認証されている' do
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

      context 'when パラメーターが異常値' do
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

    context 'when 認証されている' do
      context 'when ユーザーが所属するプロジェクト' do
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

        context 'when 画像ファイルが添付されている' do
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

          it 'when ノートを削除すると画像ファイルも削除される' do
            expect(note.images).to be_attached
            expect do
              delete v1_project_folder_note_path(
                project_id: user.projects[0].id,
                folder_id: folder.id,
                id: note.id
              ), headers: auth_headers
            end.to change(folder.notes, :count).by(-1)

            expect(response.status).to eq(200)
            expect(note.images).not_to be_attached
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

      context 'when パラメーターが異常値' do
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

    context 'when 認証されている' do
      context 'when ユーザーが所属しているプロジェクト' do
        it '画像を追加できる' do
          put v1_project_note_image_attach_path(
            project_id: user.projects[0].id,
            id: note.id
          ), params: { note: { lock_version: note.lock_version, images: image_attribute } },
             headers: auth_headers

          expect(response.status).to eq(200)
          expect(Note.find(note.id).images).to be_attached
        end
      end

      context 'when ユーザーが所属していないプロジェクト' do
        it '画像を追加できない' do
          put v1_project_note_image_attach_path(
            project_id: user_dummy.projects[0].id,
            id: note_dummy.id
          ), params: { note: { lock_version: note_dummy.lock_version, images: image_attribute } },
             headers: auth_headers
          expect(response).to have_http_status(:forbidden)
          expect(Note.find(note_dummy.id).images).not_to be_attached
        end
      end

      context 'when パラメーターが異常値の場合' do
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
