# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:note) }

  describe 'uniquness' do
    before do
      FactoryBot.create(:task)
    end

    it { is_expected.to validate_uniqueness_of(:note_id) }
  end

  describe 'タスクを作成する' do
    let(:task) { FactoryBot.build(:task) }

    it 'タスクを作成できる' do
      expect(task).to be_valid
    end
  end

  describe 'タスクを更新する（楽観排他制御）' do
    let(:task) { FactoryBot.create(:task) }

    it 'lock_versionがなければ無効な状態である' do
      task.lock_version = nil
      task.valid?(:update)
      expect(task.errors[:lock_version]).to include('を入力してください')
    end

    it 'DBのlock_versionと更新対象のlock_versionが等しい場合は有効な状態である' do
      expect(task.update(lock_version: task.lock_version)).to be_truthy
    end

    it 'DBのlock_versionと更新対象のlock_versionが異なる場合は無効な状態である' do
      expect do
        task.update(lock_version: task.lock_version - 1)
      end.to raise_error(ActiveRecord::StaleObjectError) # 楽観排他のエラー
    end
  end
end
