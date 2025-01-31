class GameMove < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :level, :column, :row, presence: true,
                                  numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0,
                                                less_than: 4 }

  validate :user_must_be_game_participant
  validate :game_must_be_in_progress
  validate :user_must_be_current_turn
  validate :position_must_be_available

  after_save :toggle_current_turn, if: :is_valid?

  private

  def user_must_be_game_participant
    return if game.nil? || user.nil?

    unless [ game.player1_id, game.player2_id ].include?(user_id)
      errors.add(:user, "must be a participant in the game")
    end
  end

  def game_must_be_in_progress
    return if game.nil?

    unless game.in_progress?
      errors.add(:game, "must be in progress")
      throw(:abort)
    end
  end

  def user_must_be_current_turn
    return if game.nil? || user.nil?

    unless game.current_turn_id == user_id
      errors.add(:user, "must be the current turn player")
    end
  end

  def position_must_be_available
    return if game.nil?
    return if level.nil? || row.nil? || column.nil?
    return unless level.between?(0, 3) && row.between?(0, 3) && column.between?(0, 3)

    if game.board_state[level][row][column] != -1
      errors.add(:base, "Position is already taken")
    end
  end

  def toggle_current_turn
    next_player = (game.current_turn == game.player1) ? game.player2 : game.player1

    game.update!(current_turn: next_player)
  end
end
