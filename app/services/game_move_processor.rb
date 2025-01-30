class GameMoveProcessor
  DEFAULT_MOVE_VALUES = {
    "level" => 0,
    "column" => 0,
    "row" => 0
  }.freeze

  def initialize(game, current_user)
    @game = game
    @current_user = current_user
  end

  def process(move_data)
    return invalid_array_format unless valid_array_format?(move_data)

    move = normalize_move_data(move_data)
    missing_fields = validate_required_fields(move)
    game_move = build_game_move(move)
    game_move.is_valid = false

    if missing_fields.any?
      game_move.save(validate: false)
      
      return error_result(
        missing_fields.map { |field| "#{field.capitalize} must be greater than or equal to 0" },
        game_move
      )
    end

    unless game_move.valid?
      game_move.save(validate: false)
      return error_result(game_move.errors.full_messages, game_move)
    end

    game_move.is_valid = true
    
    ActiveRecord::Base.transaction do
      game_move.save!
      update_board_state(game_move)
    end

    success_result(game_move)
  end

  private

  def valid_array_format?(move_data)
    return true unless move_data.is_a?(Array)
    move_data.length == 3
  end

  def invalid_array_format
    error_result(["Invalid move format"])
  end

  def normalize_move_data(move_data)
    move = if move_data.is_a?(Array)
      {
        "level" => move_data[0],
        "column" => move_data[1],
        "row" => move_data[2]
      }
    else
      move_data.is_a?(Hash) ? move_data : {}
    end

    move.transform_keys(&:to_s)
  end

  def validate_required_fields(move)
    missing_fields = []
    missing_fields << "level" unless move["level"].present?
    missing_fields << "column" unless move["column"].present?
    missing_fields << "row" unless move["row"].present?
    missing_fields
  end

  def build_game_move(move)
    # Ensure we have values (even invalid ones) to satisfy DB constraints
    move = DEFAULT_MOVE_VALUES.dup.merge(move)

    GameMove.new(
      game: @game,
      user: @current_user,
      level: move["level"],
      column: move["column"],
      row: move["row"]
    )
  end

  def update_board_state(game_move)
    player_number = @game.player1 == @current_user ? 1 : 2
    @game.board_state[game_move.level][game_move.row][game_move.column] = player_number
    @game.save!
  end

  def success_result(game_move)
    {
      success: true,
      game_move: game_move,
      errors: nil
    }
  end

  def error_result(errors, game_move = nil)
    {
      success: false,
      game_move: game_move,
      errors: errors
    }
  end
end 