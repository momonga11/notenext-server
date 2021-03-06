class Note < ApplicationRecord
  validates :title, length: { maximum: 255 }
  validates :lock_version, presence: true, on: :update
  belongs_to :project
  belongs_to :folder
  has_many_base64_attached :images
  validate :image_size, on: %i[update create], if: :images_attached?
  validate :image_type, on: %i[update create], if: :images_attached?
  after_save :purge_images, if: %i[saved_change_to_htmltext? images_attached?]

  private

  def image_size
    image = get_attached_image
    return unless image

    if image.byte_size > Rails.application.config.max_size_upload_image_file
      errors.add(:images, :too_max_image_size,
                 size: (Rails.application.config.max_size_upload_image_file / 1.megabyte).round)
    end
  end

  def image_type
    image = get_attached_image
    return unless image

    errors.add(:images, :image_type) unless image.content_type.in?(Rails.application.config.type_upload_image_file)
  end

  def get_attached_image
    image = images.select { |image| image.id.nil? }[0]
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

      # 恒久的なURLを取得し、srcと比較する
      url = Rails.application.routes.url_helpers.rails_representation_url(image.variant({}))
      if imgs_src.select { |src| src == url }.present?
        # 存在が確認できたため、比較対象から除外する
        imgs_src.delete(url)
      else
        image.purge
      end
    end
  end

  # def purge_images2
  #   # htmltextからimg要素のsrc属性を取得し、既存データと比較し、img要素が削除されていた場合は、実データを削除する
  #   # rails_representationで恒久的なURLを取得する処理のパフォーマンスが悪いと思ったので、filenameで比較し、重複している場合のみ、
  #   # URLを取得し、比較するようにした。
  #   # だが、rails_representationのパフォーマンスが思ったほど悪くないので、こちらは使わないかも...。

  #   imgs = htmltext.scan(/<img[^>]*?>/)

  #   return unless imgs.present?

  #   imgs_src = []
  #   imgs.each do |img|
  #     # 3-1.imgのsrcを取得する
  #     src = img[/(?<=src=['"])[^'"]+/]
  #     # 3-2.srcからfilename部分を抜き出しておく
  #     imgs_src << { src: src, filename: File.basename(src) } if src
  #   end

  #   # 3-3.更新対象NoteIdに紐づくblobのfilenameを取得する
  #   images_filenames = images.includes(:blob).map do |image|
  #     { image: image, filename: image.blob.filename.to_s }
  #   end
  #   # 3-4.3-2のfilenameと3-3のfilenameを比較し、3-2に存在しないfilenameのblobはパージする
  #   images_filenames.each do |i_f|
  #     i_f[:image].purge unless imgs_src.select { |i_s| i_s[:filename] == i_f[:filename] }.present?
  #   end
  #   # 3-5.3-3にて取得したfilenameに同じ値の物が複数あった場合、それらの恒久的なURLを取得する
  #   dup_images = images_filenames.select do |i_f|
  #                  i_f[:image]
  #                end&.group_by { |i_f| i_f[:filename] }.select { |_k, v| v.count > 1 }
  #   # 3-6.3-1にて取得したsrcと比較し、存在しないURLのblobをパージする
  #   dup_images.each do |filename, dup_i_fs|
  #     dup_i_fs.each do |dup_i_f|
  #       # 比較対象が存在しない場合は、削除されたと判定する
  #       unless imgs_src&.select { |i_s| i_s[:filename] == filename }.present?
  #         dup_i_f[:image].purge
  #         next
  #       end

  #       # 恒久的なURLを取得する
  #       url = Rails.application.routes.url_helpers.rails_representation_url(dup_i_f[:image].variant({}))
  #       if imgs_src.select { |i_s| i_s[:src] == url }.present?
  #         # 存在が確認できたため、比較対象から除外する
  #         imgs_src.reject! { |i_s| i_s[:src] == url }
  #       else
  #         dup_i_f[:image].purge
  #       end
  #     end
  #   end
  # end
end
