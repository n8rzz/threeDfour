class GameChannel < ApplicationCable::Channel
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
    Rails.logger.info "GameChannel#receive: Received data: #{data.inspect}"
    
    game = Game.find(data["game_id"])
    return unless game

    if @game_session
      @game_session.update(last_seen_at: Time.current)
    end

    move_data = data["move"]
    Rails.logger.info "GameChannel#receive: Processing move: #{move_data.inspect}"

    # Convert array format to hash format if needed
    move = if move_data.is_a?(Array)
      {
        "level" => move_data[0],
        "column" => move_data[1],
        "row" => move_data[2]
      }
    else
      move_data
    end

    game_move = GameMove.new(
      game: game,
      user: current_user,
      level: move["level"],
      column: move["column"],
      row: move["row"]
    )

    Rails.logger.info "GameChannel#receive: Created GameMove: #{game_move.inspect}"
    Rails.logger.info "GameChannel#receive: GameMove valid? #{game_move.valid?}"
    Rails.logger.info "GameChannel#receive: GameMove errors: #{game_move.errors.full_messages}" unless game_move.valid?

    if game_move.valid?
      game_move.is_valid = true # Later this will be replaced with actual move validation
      game_move.save!
      Rails.logger.info "GameChannel#receive: Broadcasting success"
      broadcast_success(game_move)
    else
      game_move.is_valid = false
      game_move.save(validate: false)
      Rails.logger.info "GameChannel#receive: Broadcasting error"
      broadcast_error(game, game_move.errors.full_messages) # Send all error messages
    end
  end

  private

  def broadcast_success(game_move)
    message = {
      type: "move",
      status: "success",
      move: {
        level: game_move.level,
        column: game_move.column,
        row: game_move.row,
        user_id: game_move.user_id
      },
      current_turn_id: game_move.game.current_turn_id
    }
    
    Rails.logger.info "GameChannel#broadcast_success: Broadcasting: #{message.inspect}"
    ActionCable.server.broadcast("game_#{game_move.game_id}", message)
  end

  def broadcast_error(game, errors)
    message = {
      type: "move",
      status: "error",
      errors: errors
    }
    Rails.logger.info "GameChannel#broadcast_error: Broadcasting: #{message.inspect}"
    ActionCable.server.broadcast("game_#{game.id}", message)
  end
end
