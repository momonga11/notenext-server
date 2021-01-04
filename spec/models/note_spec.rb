require 'rails_helper'

RSpec.describe Note, type: :model do
  it { is_expected.to validate_length_of(:title).is_at_most(255) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:folder) }

  describe 'ノートを作成する' do
    let(:note) { FactoryBot.build(:note) }

    it 'ノートを作成できる' do
      expect(note).to be_valid
    end
  end

  describe 'ノートを更新する（楽観排他制御）' do
    let(:note) { FactoryBot.create(:note) }

    it 'lock_versionがなければ無効な状態である' do
      note.lock_version = nil
      note.valid?(:update)
      expect(note.errors[:lock_version]).to include('を入力してください')
    end

    it 'DBのlock_versionと更新対象のlock_versionが等しい場合は有効な状態である' do
      expect(note.update(lock_version: note.lock_version)).to be_truthy
    end

    it 'DBのlock_versionと更新対象のlock_versionが異なる場合は無効な状態である' do
      expect do
        note.update(lock_version: note.lock_version - 1)
      end.to raise_error(ActiveRecord::StaleObjectError) # 楽観排他のエラー
    end
  end
end
