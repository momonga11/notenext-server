# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks', type: :request do
  include JsonSupport

  let(:user) { FactoryBot.create(:user, :user_with_projects) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:folder) { FactoryBot.create(:folder, project: user.projects[0]) }
  let(:note) { FactoryBot.create(:note, project: user.projects[0], folder: folder) }
  let(:task) { FactoryBot.create(:task, project: user.projects[0], note: note) }
  let(:user_dummy) { FactoryBot.create(:user, :user_with_projects) }
  let(:folder_dummy) { FactoryBot.create(:folder, project: user_dummy.projects[0]) }
  let(:note_dummy) { FactoryBot.create(:note, project: user_dummy.projects[0], folder: folder_dummy) }
  let(:task_dummy) { FactoryBot.create(:task, project: user_dummy.projects[0], note: note_dummy) }

  describe 'POST #create' do
    subject :create_task do
      post v1_project_note_tasks_path(project_id: project_id, note_id: note_id), params: task_attributes,
                                                                                 headers: auth_headers
      response
    end

    let(:task_attributes) { { task: FactoryBot.attributes_for(:task) } }
    let(:project_id) { user.projects[0].id }
    let(:note_id) { note.id }

    context 'when 認証されていない' do
      it '作成できない' do
        auth_headers['access-token'] = '12345'

        expect(create_task).to have_http_status(:unauthorized)
        expect(note.task).to eq nil
      end
    end

    context 'when 認証されている' do
      it 'ユーザーが所属しているプロジェクトの場合、タスクが作成できる' do
        expect(create_task).to have_http_status(:created)
        expect(note.task).not_to eq nil
      end

      context 'when プロジェクトにユーザーが所属していない' do
        let(:project_id) { user_dummy.projects[0].id }

        it '作成できない' do
          expect(create_task).to have_http_status(:forbidden)
          expect(note.task).to eq nil
        end
      end

      context 'when パラメーターが異常値' do
        context 'when パラメーターが想定していない' do
          let(:task_attributes) { 'test' }

          it '作成できない' do
            expect(create_task).to have_http_status(:bad_request)
            expect(note.task).to eq nil
          end
        end

        context 'when not exist note_id' do
          let(:note_id) { -1 }

          it '存在しないノートIDの場合は作成できない' do
            expect(create_task).to have_http_status(:not_found)
            expect(note.task).to eq nil
          end
        end
      end
    end
  end

  describe 'PUT #update' do
    subject :update_task do
      put v1_project_note_task_path(project_id: project_id, note_id: note_id, id: task_id), params: task2_attributes,
                                                                                            headers: auth_headers
      response
    end

    let(:project_id) { user.projects[0].id }
    let(:note_id) { note.id }
    let(:task_id) { task.id }
    let(:task2_attributes) { { task: FactoryBot.attributes_for(:task2) } }

    context 'when 認証されていない' do
      it '更新できない' do
        auth_headers['access-token'] = '12345'

        expect(update_task).to have_http_status(:unauthorized)
      end
    end

    context 'when 認証されている' do
      context 'when プロジェクトにユーザーが所属している' do
        it '更新できる' do
          expect(update_task).to have_http_status(:ok)
          expect(json_parse_body(response)[:date_to]).to eq(task2_attributes[:task][:date_to])
        end
      end

      context 'when プロジェクトにユーザーが所属していない' do
        let(:project_id) { user_dummy.projects[0].id }

        it '更新できない' do
          expect(update_task).to have_http_status(:forbidden)
          expect(json_parse_body(response)[:date_to]).not_to eq(task2_attributes[:task][:date_to])
        end
      end

      context 'when パラメーターが異常値' do
        context 'when パラメーターの値が想定外' do
          let(:task2_attributes) { { test: 'test' } }

          it '更新できない' do
            expect(update_task).to have_http_status(:bad_request)
          end
        end

        context 'when パラメーターにlock_versionが存在しない場合' do
          it '更新できない' do
            task2_attributes[:task].reject! { |k| k == :lock_version }
            expect(update_task).to have_http_status(:bad_request)
          end
        end

        context 'when DBのlock_versionと更新対象のlock_versionが異なる' do
          it '更新できない' do
            task2_attributes[:task][:lock_version] = -1
            expect(update_task).to have_http_status(:conflict)
          end
        end

        context 'when id is not exist' do
          let(:task_id) { -1 }

          it '更新できない' do
            expect(update_task).to have_http_status(:not_found)
          end
        end

        context 'when note_id is not exist' do
          let(:note_id) { -1 }

          it '更新できない' do
            expect(update_task).to have_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'DELETE #delete' do
    subject :delete_task do
      delete v1_project_note_task_path(project_id: project_id, note_id: note_id, id: task_id), headers: auth_headers
      response
    end

    let(:project_id) { user.projects[0].id }
    let(:note_id) { note.id }
    let(:task_id) { task.id }

    # expect内で作成しないよう、事前に作成しておく
    let!(:task) { FactoryBot.create(:task, project: user.projects[0], note: note) }
    let!(:task_dummy) { FactoryBot.create(:task, project: user_dummy.projects[0]) }

    context 'when 認証されていない' do
      it '削除できない' do
        auth_headers['access-token'] = '12345'
        expect(delete_task).to have_http_status(:unauthorized)
        expect(Task.find_by(id: note.task.id)).not_to eq nil
      end
    end

    context 'when 認証されている' do
      context 'when プロジェクトにユーザーが所属している' do
        it '削除できる' do
          expect(delete_task).to have_http_status(:ok)
          expect(Task.find_by(id: note.task.id)).to eq nil
        end
      end

      context 'when プロジェクトにユーザーが所属していない' do
        let(:project_id) { user_dummy.projects[0].id }

        it '削除できない' do
          expect(delete_task).to have_http_status(:forbidden)
          expect(Task.find_by(id: note.task.id)).not_to eq nil
        end
      end

      context 'when パラメーターが異常値' do
        context 'when id is not exist' do
          let(:task_id) { -1 }

          it '削除できない' do
            expect(delete_task).to have_http_status(:not_found)
            expect(Task.find_by(id: note.task.id)).not_to eq nil
          end
        end

        context 'when note_id is not exist' do
          let(:note_id) { -1 }

          it '削除できない' do
            expect(delete_task).to have_http_status(:not_found)
            expect(Task.find_by(id: note.task.id)).not_to eq nil
          end
        end
      end
    end
  end
end
