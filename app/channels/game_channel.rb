class GameChannel < ApplicationCable::Channel
  MESSAGE_TYPE = {
    move: "move"
  }.freeze

  MESSAGE_STATUS = {
    success: "success",
    error: "error"
  }.freeze

  def subscribed
    @game_id = params[:game_id]

    reject and return unless current_user
    stream_from "game_#{@game_id}" if @game_id

    @game_session = GameSession.find_or_initialize_by(
      game_id: @game_id,
      user_id: current_user.id
    )
    @game_session.session_id = connection.connection_identifier
    @game_session.last_seen_at = Time.current
    @game_session.save
  end

  def unsubscribed
    stop_all_streams
    
    if @game_id && current_user
      GameSession.where(
        game_id: @game_id,
        user_id: current_user.id
      ).delete_all
    end
  end

  def receive(data)
    begin
      game = Game.find(data["game_id"])
    rescue ActiveRecord::RecordNotFound
      return
    end

    # Update last_seen_at but don't block move processing if it fails
    @game_session&.update(last_seen_at: Time.current)

    move_data = data["move"]
    
    # Early return for invalid array format
    if move_data.is_a?(Array) && move_data.length != 3
      broadcast_error(game, ["Invalid move format"])
      return
    end

    move = if move_data.is_a?(Array)
      {
        "level" => move_data[0],
        "column" => move_data[1],
        "row" => move_data[2]
      }
    else
      move_data.is_a?(Hash) ? move_data : {}
    end

    # Check for missing required fields
    missing_fields = []
    missing_fields << "level" unless move["level"].present?
    missing_fields << "column" unless move["column"].present?
    missing_fields << "row" unless move["row"].present?

    # Ensure we have values (even invalid ones) to satisfy DB constraints
    move = {
      "level" => 0,
      "column" => 0,
      "row" => 0
    }.merge(move.transform_keys(&:to_s))

    game_move = build_game_move(game, move)
    game_move.is_valid = false

    if missing_fields.any?
      game_move.save(validate: false)
      broadcast_error(game, missing_fields.map { |field| "#{field.capitalize} must be greater than or equal to 0" })
      return
    end

    unless game_move.valid?
      game_move.save(validate: false)
      broadcast_error(game, game_move.errors.full_messages)
      return
    end

    game_move.is_valid = true
    game_move.save!
    broadcast_success(game_move)
  end

  private

  def broadcast_success(game_move)
    message = {
      type: MESSAGE_TYPE[:move],
      status: MESSAGE_STATUS[:success],
      move: {
        level: game_move.level,
        column: game_move.column,
        row: game_move.row,
        user_id: game_move.user_id
      },
      # Used for updating turn indicators and enabling/disabling move buttons
      current_turn_id: game_move.game.current_turn_id
    }
    
    ActionCable.server.broadcast("game_#{game_move.game_id}", message)
  end

  def broadcast_error(game, errors)
    message = {
      type: MESSAGE_TYPE[:move],
      status: MESSAGE_STATUS[:error],
      errors: errors
    }

    ActionCable.server.broadcast("game_#{game.id}", message)
  end

  def build_game_move(game, move)
    GameMove.new(
      game: game,
      user: current_user,
      level: move["level"],
      column: move["column"],
      row: move["row"]
    )
  end
end
