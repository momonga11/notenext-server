# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Note, type: :model do
  it { is_expected.to validate_length_of(:title).is_at_most(255) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:folder) }
  it { is_expected.to have_one(:task).dependent(:destroy) }

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

    context 'when update' do
      it 'imagesが存在すれば更新できること' do
        note.update(images: images)
        expect(note.images).to be_attached
      end

      context 'when attach_images' do
        before do
          note.update(images: images)
        end

        it 'imagesは複数追加できること' do
          expect do
            note.update(images: images)
          end.to change(note.images, :count).by(1)
        end

        context 'when over images_size' do
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

        context 'when different images_type' do
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

    context 'when destroy' do
      before do
        note.update(images: images)
      end

      it 'noteを削除すると、imagesのファイルも削除されること' do
        expect(note.destroy).to be_truthy
        expect(note.images).not_to be_attached
      end
    end

    describe 'update htmltext with img' do
      let!(:img_url) do
        note.update(images: images)

        image = note.images.sort_by(&:id).reverse[0]
        url = Rails.application.routes.url_helpers.url_for(image)
        "<img src=\"#{url}\">"
      end

      # テストでは利用しないが、複数分作成するために実行する
      let!(:img_url2) do
        images64 = Base64.encode64(IO.read('spec/fixtures/neko_test.jpg'))
        images2 = { data: "data:image/jpeg;base64,#{images64}", filename: 'neko_test2.jpg' }

        note.update(images: images2)

        image = note.images.sort_by(&:id).reverse[0]
        url = Rails.application.routes.url_helpers.url_for(image)
        "<img src=\"#{url}\">"
      end

      context 'when img要素を1/2削除した' do
        it '対象の画像ファイルが削除されること' do
          expect do
            note.update(htmltext: "<p>hoge</p>#{img_url}<p>fuga</p>")
          end.to change(described_class.find(note.id).images, :count).by(-1)
          expect(described_class.find(note.id).images.count).to be 1
          expect(described_class.find(note.id).images[0].blob.filename == 'neko_test.jpg').to be_truthy
        end
      end

      context 'when img要素を2/2削除した' do
        it '画像ファイルが全て削除されること' do
          expect do
            note.update(htmltext: '<p>hoge</p>')
          end.to change { described_class.find(note.id).images.attached? }.from(true).to(false)
        end
      end
    end
  end

  describe 'ノートを曖昧検索する' do
    let!(:note) { FactoryBot.create(:note) }
    let!(:note2) { FactoryBot.create(:note2) }
    let!(:note3) { FactoryBot.create(:note3) }
    let!(:note_empty_title_text) { FactoryBot.create(:note_empty_title_text) }

    it 'titleを部分一致検索できること' do
      expect(described_class.all.search_ambiguous_text('NoteT')[0].id).to be note3.id
    end

    it 'textを部分一致検索できること' do
      notes = described_class.all.search_ambiguous_text('田舎')
      expect(notes).to include note2, note3
      expect(notes).not_to include note
    end

    it '検索対象が空文字の場合に、titleとtextがNullのレコードが取得できること' do
      notes = described_class.all.search_ambiguous_text('')
      expect(notes).to include note_empty_title_text
    end

    it '検索対象がNullの場合に、titleとtextがNullのレコードが取得できること' do
      notes = described_class.all.search_ambiguous_text(nil)
      expect(notes).to include note_empty_title_text
    end
  end
end
