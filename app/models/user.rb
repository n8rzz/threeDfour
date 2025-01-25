class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  validates :username, presence: true, uniqueness: true
  validates :avatar_url, allow_blank: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
end
