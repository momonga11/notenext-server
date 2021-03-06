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
    let(:user) { FactoryBot.create(:user_new) }
    let(:avatar) do
      avatar64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
      { data: "data:image/jpeg;base64,#{avatar64}", filename: 'neko_test.jpg' }
    end

    context 'update' do
      it 'avatarが存在すれば更新できること' do
        user.update(avatar: avatar)
        expect(user.avatar.attached?).to be_truthy
      end

      context 'avatar_size' do
        before do
          @max_size = Rails.application.config.max_size_upload_image_file
          Rails.application.config.max_size_upload_image_file = 1.kilobyte
        end

        after do
          Rails.application.config.max_size_upload_image_file = @max_size
        end

        it 'avatarのサイズが最大サイズ以上の場合、エラーとなること' do
          user.update(avatar: avatar)
          expect(user.errors[:avatar]).to include('のサイズは0MB以下にしてください')
        end
      end

      context 'avatar_type' do
        before do
          @type = Rails.application.config.type_upload_image_file
          Rails.application.config.type_upload_image_file = %('image/png')
        end

        after do
          Rails.application.config.type_upload_image_file = @type
        end

        it 'avatarの形式が許容されている拡張子以外の場合、エラーとなること' do
          user.update(avatar: avatar)
          expect(user.errors[:avatar]).to include('にはjpegまたはpng形式のファイルを選択してください')
        end
      end
    end

    context 'destroy' do
      before do
        user.update(avatar: avatar)
      end

      it 'userを削除すると、avatarのファイルも削除されること' do
        sleep(1) # DBのロールバックが追いつかないのか、ここで時間をおかないと後続テストでエラーが出るため、待機する
        expect(user.destroy).to be_truthy
        expect(user.avatar.attached?).to be_falsey
      end
    end
  end
end
