require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:users_projects).dependent(:destroy) }
  it { is_expected.to have_many(:projects).through(:users_projects) }
  it { is_expected.to validate_confirmation_of(:password) }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }

  describe 'uniquness' do
    before do
      FactoryBot.create(:user_new)
    end

    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }

    # emailのユニーク制約はdeviseとの関係でShoulda Matchersでは正常に検証できなかっため、独自でチェックする
    it 'is invalid with a duplicate email address' do
      user = FactoryBot.build(:user_new)
      user.valid?
      expect(user.errors[:email].to_s).to include('すでに存在します')
    end
  end

  describe 'attach avatar' do
    let(:user) { FactoryBot.build(:user_new) }
    let(:avatar) do
      avatar64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
      { data: "data:image/jpeg;base64,#{avatar64}", filename: 'neko_test.jpg' }
    end

    context 'update' do
      it 'avatarが存在すれば登録できること' do
        user.update(avatar: avatar)
        expect(user.avatar.attached?).to be_truthy
      end
    end

    context 'destroy' do
      before do
        user.update(avatar: avatar)
      end

      it 'userを削除すると、avatarのファイルも削除されること' do
        expect(user.destroy).to be_truthy
        expect(user.avatar.attached?).to be_falsey
        sleep(0.5) # DBのロールバックが追いつかないのか、ここで時間をおかないと後続テストでエラーが出るため、待機する
      end
    end
  end
end
