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
    game = Game.find(data["game_id"])

    return unless game

    if @game_session
      @game_session.update(last_seen_at: Time.current)
    end

    ActionCable.server.broadcast(
      "game_#{game.id}",
      {
        type: "move",
        user_id: data["user_id"],
        move: data["move"]
      }
    )
  end
end
