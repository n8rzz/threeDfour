class GameChannel < ApplicationCable::Channel
  include GameBroadcaster

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

    result = GameMoveProcessor.new(game, current_user).process(data["move"])

    if result[:success]
      broadcast_success(result[:game_move])
    else
      broadcast_error(game, result[:errors])
    end
  end
end
