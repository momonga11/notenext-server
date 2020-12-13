require 'rails_helper'

RSpec.describe Folder, type: :model do
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:notes).dependent(:destroy) }

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
end
