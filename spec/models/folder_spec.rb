# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folder, type: :model do
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:notes).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).through(:notes) }
  it { is_expected.to have_many(:tasks_not_completed).conditions(completed: false).through(:notes).source(:task) }

  describe 'フォルダを作成する' do
    let(:folder) { FactoryBot.build(:folder) }

    it 'フォルダを作成できる' do
      expect(folder).to be_valid
    end
  end

  describe 'フォルダを更新する（楽観排他制御）' do
    let(:folder) { FactoryBot.create(:folder) }

    it 'lock_versionがなければ無効な状態である' do
      folder.lock_version = nil
      folder.valid?(:update)
      expect(folder.errors[:lock_version]).to include('を入力してください')
    end

    it 'DBのlock_versionと更新対象のlock_versionが等しい場合は有効な状態である' do
      expect(folder.update(lock_version: folder.lock_version)).to be_truthy
    end

    it 'DBのlock_versionと更新対象のlock_versionが異なる場合は無効な状態である' do
      expect do
        folder.update(lock_version: folder.lock_version - 1)
      end.to raise_error(ActiveRecord::StaleObjectError) # 楽観排他のエラー
    end
  end

  describe '複数フォルダに完了していないタスクの件数を取得する' do
    let(:folder) { FactoryBot.create(:folder) }
    let(:folder2) { FactoryBot.create(:folder) }

    context 'when task is exists and task.completed = false' do
      before do
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder2))
      end

      it 'タスクの件数に計上される' do
        folders = described_class.all.select_tasks_count
        expect(folders.select { |f| f.id == folder.id }[0].tasks_count).to eq(2)
        expect(folders.select { |f| f.id == folder2.id }[0].tasks_count).to eq(1)
      end

      it '並び順がid順になっていること' do
        folders = described_class.all.select_tasks_count
        expect(folders[0].id < folders[1].id).to be_truthy
      end
    end

    context 'when task is not exists' do
      before do
        FactoryBot.create_list(:note, 2, folder: folder)
        FactoryBot.create_list(:note, 2, folder: folder2)
      end

      it 'タスクの件数に計上されない' do
        folders = described_class.all.select_tasks_count

        folders.each do |f|
          expect(f.tasks_count).to eq 0
        end
      end
    end

    context 'when task is exists and task.completed = true' do
      before do
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder), completed: true)
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder), completed: true)
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder2), completed: true)
      end

      it 'タスクの件数に計上されない' do
        folders = described_class.all.select_tasks_count

        folders.each do |f|
          expect(f.tasks_count).to eq 0
        end
      end
    end
  end

  describe '単一フォルダに完了していないタスクの件数を取得する' do
    let(:folder) { FactoryBot.create(:folder) }

    context 'when task is exists and task.completed = false' do
      before do
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder))
      end

      it 'タスクの件数に計上される' do
        expect(folder.with_tasks_count['tasks_count']).to eq(2)
      end
    end

    context 'when task is not exists' do
      before do
        FactoryBot.create_list(:note, 2, folder: folder)
      end

      it 'タスクの件数に計上されない' do
        expect(folder.with_tasks_count['tasks_count']).to eq(0)
      end
    end

    context 'when task is exists and task.completed = true' do
      before do
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder), completed: true)
        FactoryBot.create(:task, note: FactoryBot.create(:note, folder: folder), completed: true)
      end

      it 'タスクの件数に計上されない' do
        expect(folder.with_tasks_count['tasks_count']).to eq(0)
      end
    end
  end
end
