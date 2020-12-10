# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :lockable
  include DeviseTokenAuth::Concerns::User

  # validate :password, confirmation: true
  # validates :email, uniqueness: true
  has_many :users_projects, dependent: :destroy
  has_many :projects, through: :users_projects
end
