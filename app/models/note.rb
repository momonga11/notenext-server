# frozen_string_literal: true

# ノートのモデルクラス
class Note < ApplicationRecord
  validates :title, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  belongs_to :project
  belongs_to :folder
  has_many_base64_attached :images
  validate :image_size, on: %i[update create], if: :images_attached?
  validate :image_type, on: %i[update create], if: :images_attached?
  after_save :purge_images, if: %i[saved_change_to_htmltext? images_attached?]

  # テキストカラムの曖昧検索を実行する
  def self.search_ambiguous_text(text)
    where('title like ?', "%#{text}%").or(Note.where('text like ?', "%#{text}%"))
  end

  private

  after_destroy do |note|
    note.images = nil if note.images.attached?
  end

  def image_size
    image = attached_image
    return unless image

    return unless image.byte_size > Rails.application.config.max_size_upload_image_file

    errors.add(:images, :too_max_image_size,
               size: (Rails.application.config.max_size_upload_image_file / 1.megabyte).round)
  end

  def image_type
    image = attached_image
    return unless image

    errors.add(:images, :image_type) unless image.content_type.in?(Rails.application.config.type_upload_image_file)
  end

  def attached_image
    image = images.select { |i| i.id.nil? }[0]
    image || nil
  end

  def images_attached?
    images.attached?
  end

  def purge_images
    imgs = htmltext.scan(/<img[^>]*?>/)

    imgs_src = []
    imgs.each do |img|
      src = img[/(?<=src=['"])[^'"]+/]
      imgs_src << src if src
    end

    images.each do |image|
      # 比較対象が存在しない場合は、削除されたと判定する
      unless imgs_src.present?
        image.purge
        next
      end

      # URLを取得し、srcと比較する
      url = Rails.application.routes.url_helpers.url_for(image)
      if imgs_src.select { |src| src == url }.present?
        # 存在が確認できたため、比較対象から除外する
        imgs_src.delete(url)
      else
        image.purge
      end
    end
  end
end
