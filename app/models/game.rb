class Game < ApplicationRecord
  DEFAULT_BOARD_STATE = Array.new(4) { Array.new(4) { Array.new(4, -1) } }.freeze

  include AASM

  after_initialize :set_default_board_state, if: :new_record?

  belongs_to :player1, class_name: "User"
  belongs_to :player2, class_name: "User", optional: true
  belongs_to :current_turn, class_name: "User"
  belongs_to :winner, class_name: "User", optional: true
  has_many :game_moves

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
      before do
        self.current_turn = player1

        serialize_move_history
      end

      after do
        save!
      end

      transitions from: :in_progress, to: :complete
    end

    event :abandon do
      before do
        self.current_turn = player1
        serialize_move_history
      end

      after do
        save!
      end

      transitions from: [ :waiting, :in_progress ], to: :abandoned
    end
  end

  def place_move(level, row, column, player_number)
    return false unless [ 1, 2 ].include?(player_number)
    return false unless [ level, row, column ].all? { |n| n.between?(0, 3) }

    board_state[level][row][column] = player_number
    save
  end

  private

  def set_default_board_state
    self.board_state ||= DEFAULT_BOARD_STATE.deep_dup
  end

  def serialize_move_history
    return true unless game_moves.any?

    self.move_history = game_moves.order(:created_at).map do |move|
      {
        user_id: move.user_id,
        level: move.level,
        column: move.column,
        row: move.row,
        created_at: move.created_at,
        is_valid: move.is_valid
      }
    end
  end

  def finalize_game
    save!
  end

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
    return if current_turn_id.nil?

    if in_progress? && ![ player1_id, player2_id ].include?(current_turn_id)
      errors.add(:current_turn, "must be one of the players")

      return
    end

    return if in_progress?

    errors.add(:current_turn, "must be player1 when not in progress") unless current_turn_id == player1_id
  end

  def has_player2?
    player2.present?
  end
end
