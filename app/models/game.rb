class Game < ApplicationRecord
  include AASM

  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User", optional: true
  belongs_to :current_turn, class_name: "User"
  belongs_to :winner, class_name: "User", optional: true

  validates :board_state, presence: true
  validate :validate_game_state
  validate :validate_winner
  validate :validate_current_turn

  scope :by_recent, -> { order(updated_at: :desc) }
  scope :for_user, ->(user) {
    where(player1: user).or(where(player2: user))
  }
  scope :available_to_join, ->(user) {
    where(status: :waiting).where.not(player1: user)
  }

  aasm column: :status do
    state :waiting, initial: true
    state :in_progress
    state :complete
    state :abandoned

    event :start do
      transitions from: :waiting, to: :in_progress, guard: :has_player2?
    end

    event :complete_game do
      transitions from: :in_progress, to: :complete
    end

    event :abandon do
      before do
        self.current_turn = player1
      end

      transitions from: [ :waiting, :in_progress ], to: :abandoned
    end
  end

  private

  def validate_game_state
    return if waiting?
    errors.add(:player2, "must be present for in-progress game") if in_progress? && !player2
    errors.add(:player2, "must be present for complete game") if complete? && !player2
  end

  def validate_winner
    return unless winner_id
    if !player2_id || waiting? || abandoned?
      errors.add(:winner, "can't be set unless game is complete with two players")
    end
  end

  def validate_current_turn
    if in_progress?
      unless [ player1_id, player2_id ].include?(current_turn_id)
        errors.add(:current_turn, "must be one of the players")
      end
    else
      unless current_turn_id == player1_id
        errors.add(:current_turn, "must be player1 when not in progress")
      end
    end
  end

  def has_player2?
    player2.present?
  end
end
