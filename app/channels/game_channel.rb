class GameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:game_id]
    
    stream_from "game_#{@game_id}" if @game_id
  end

  def unsubscribed
    stop_all_streams
  end

  def receive(data)
    game = Game.find(data['game_id'])
    
    return unless game

    ActionCable.server.broadcast(
      "game_#{game.id}",
      {
        type: 'move',
        user_id: data['user_id'],
        move: data['move']
      }
    )
  end
end
