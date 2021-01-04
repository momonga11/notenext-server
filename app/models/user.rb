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

  after_destroy do |user|
    user.avatar.purge if user.avatar.attached?
  end
end
