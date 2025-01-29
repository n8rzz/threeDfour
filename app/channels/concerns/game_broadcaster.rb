module GameBroadcaster
  extend ActiveSupport::Concern

  # Message types for game-related broadcasts
  MESSAGE_TYPE = {
    move: "move",
    player_status: "player_status"
  }.freeze

  # Status types for game-related broadcasts
  MESSAGE_STATUS = {
    success: "success",
    error: "error"
  }.freeze

  private

  # Broadcasts a successful move to all players in the game
  # @param game_move [GameMove] The move that was successfully made
  # The broadcast includes the move details and the next player's turn,
  # which is used by the UI to:
  # - Update the game board with the new move
  # - Update turn indicators
  # - Enable/disable move buttons based on whose turn it is
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
      current_turn_id: game_move.game.current_turn_id
    }
    
    ActionCable.server.broadcast("game_#{game_move.game_id}", message)
  end

  # Broadcasts an error message to all players in the game
  # @param game [Game] The game where the error occurred
  # @param errors [Array<String>] List of error messages to broadcast
  def broadcast_error(game, errors)
    message = {
      type: MESSAGE_TYPE[:move],
      status: MESSAGE_STATUS[:error],
      errors: errors
    }

    ActionCable.server.broadcast("game_#{game.id}", message)
  end

  # Broadcasts a player's status change to all players in the game
  # @param game [Game] The game the player is in
  # @param user [User] The user whose status changed
  # @param connected [Boolean] Whether the user connected or disconnected
  def broadcast_player_status(game, user, connected)
    message = {
      type: MESSAGE_TYPE[:player_status],
      status: MESSAGE_STATUS[:success],
      user_id: user.id,
      connected: connected
    }
    
    ActionCable.server.broadcast("game_#{game.id}", message)
  end
end 