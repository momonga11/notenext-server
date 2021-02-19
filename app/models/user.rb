# frozen_string_literal: true

class User < ActiveRecord::Base
  include ActiveStorageSupport::SupportForBase64
  # Include default devise modules. Others available are:
  # :lockable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :confirmable
  include DeviseTokenAuth::Concerns::User

  validates :password, confirmation: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, uniqueness: { case_sensitive: true }
  validates :uid, uniqueness: { scope: :provider, case_sensitive: true }
  has_many :users_projects, dependent: :destroy
  has_many :projects, through: :users_projects
  has_one_base64_attached :avatar
  validate :avatar_size, on: [:update,:create]
  validate :avatar_type, on: [:update,:create]

  after_destroy do |user|
    user.avatar.purge if user.avatar.attached?
  end

  def avatar_size
    return unless avatar.attached?

    if avatar.byte_size > Rails.application.config.max_size_upload_image_file
      errors.add(:avatar, :too_max_image_size,
                 size: (Rails.application.config.max_size_upload_image_file / 1.megabyte).round)
    end
  end

  def avatar_type
    return unless avatar.attached?

    errors.add(:avatar, :image_type) unless avatar.content_type.in?(Rails.application.config.type_upload_image_file)
  end
end
