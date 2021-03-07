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

  describe 'attach purge images' do
    let(:note) { FactoryBot.create(:note) }
    let(:images) do
      images64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
      { data: "data:image/jpeg;base64,#{images64}", filename: 'neko_test.jpg' }
    end

    context 'update' do
      it 'imagesが存在すれば更新できること' do
        note.update(images: images)
        expect(note.images.attached?).to be_truthy
      end

      context 'attach_images' do
        before do
          note.update(images: images)
        end

        it 'imagesは複数追加できること' do
          expect do
            note.update(images: images)
          end.to change(note.images, :count).by(1)
        end

        context 'images_size' do
          before do
            @max_size = Rails.application.config.max_size_upload_image_file
            Rails.application.config.max_size_upload_image_file = 1.kilobyte
          end

          after do
            Rails.application.config.max_size_upload_image_file = @max_size
          end

          it 'imagesのサイズが最大サイズ以上の場合、エラーとなること' do
            note.update(images: images)
            expect(note.errors[:images]).to include('のサイズは0MB以下にしてください')
          end
        end

        context 'images_type' do
          before do
            @type = Rails.application.config.type_upload_image_file
            Rails.application.config.type_upload_image_file = %('image/png')
          end

          after do
            Rails.application.config.type_upload_image_file = @type
          end

          it 'imagesの形式が許容されている拡張子以外の場合、エラーとなること' do
            note.update(images: images)
            expect(note.errors[:images]).to include('にはjpegまたはpng形式のファイルを選択してください')
          end
        end
      end
    end

    context 'destroy' do
      before do
        note.update(images: images)
      end

      it 'noteを削除すると、imagesのファイルも削除されること' do
        expect(note.destroy).to be_truthy
        expect(note.images.attached?).to be_falsey
      end
    end

    describe 'update htmltext with img', focus: :true do
      let!(:img_url) do
        note.update(images: images)

        image = note.images.sort_by { |image| image.id }.reverse[0]
        url = Rails.application.routes.url_helpers.url_for(image)
        "<img src=\"#{url}\">"
      end

      let!(:img_url2) do
        images64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
        images2 = { data: "data:image/jpeg;base64,#{images64}", filename: 'neko_test2.jpg' }

        note.update(images: images2)

        image = note.images.sort_by { |image| image.id }.reverse[0]
        url = Rails.application.routes.url_helpers.url_for(image)
        "<img src=\"#{url}\">"
      end

      context 'img要素を1/2削除した場合' do
        it '対象の画像ファイルが削除されること' do
          expect do
            note.update(htmltext: "<p>hoge</p>#{img_url}<p>fuga</p>")
          end.to change(Note.find(note.id).images, :count).by(-1)
          expect(Note.find(note.id).images.count).to be 1
          expect(Note.find(note.id).images[0].blob.filename == 'neko_test.jpg').to be_truthy
        end
      end

      context 'img要素を2/2削除した場合' do
        it '画像ファイルが全て削除されること' do
          expect do
            note.update(htmltext: '<p>hoge</p>')
          end.to change { Note.find(note.id).images.attached? }.from(true).to(false)
        end
      end
    end
  end
end
