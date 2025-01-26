class GameSession < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :session_id, presence: true, uniqueness: true
end
