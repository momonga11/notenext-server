# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to have_many(:folders).dependent(:destroy) }
  it { is_expected.to have_many(:notes).dependent(:destroy) }
  it { is_expected.to have_many(:users_projects).dependent(:destroy) }
  it { is_expected.to have_many(:users).through(:users_projects) }

  describe 'プロジェクトを作成する' do
    let(:user) { FactoryBot.create(:user) }
    let(:user_with_project) { FactoryBot.create(:user, :user_with_projects) }

    it '1ユーザーは1プロジェクトを作成できる' do
      project = described_class.new(name: 'test', users: Array.new(1, user))
      expect(project).to be_valid
    end

    it '1ユーザーは2つ以上のプロジェクトを作成できない' do
      project = described_class.new(name: 'test', users: Array.new(1, user_with_project))
      project.valid?
      expect(project.errors[:base]).to include('ユーザーが作成できるプロジェクト数の上限を越えているため、作成できません。')
    end
  end

  describe 'プロジェクトを更新する（楽観排他制御）' do
    let(:project) { FactoryBot.create(:project) }

    it 'lock_versionがなければ無効な状態である' do
      project.lock_version = nil
      project.valid?(:update)
      expect(project.errors[:lock_version]).to include('を入力してください')
    end

    it 'DBのlock_versionと更新対象のlock_versionが等しい場合は有効な状態である' do
      expect(project.update(lock_version: project.lock_version)).to be_truthy
    end

    it 'DBのlock_versionと更新対象のlock_versionが異なる場合は無効な状態である' do
      expect do
        project.update(lock_version: project.lock_version - 1)
      end.to raise_error(ActiveRecord::StaleObjectError) # 楽観排他のエラー
    end
  end
end
