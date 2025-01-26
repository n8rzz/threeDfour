class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :join, :abandon]

  def index
    @games = Game.where(status: :waiting).where.not(player1: current_user)
  end

  def my_games
    @games = Game.where(player1: current_user)
                 .or(Game.where(player2: current_user))
                 .order(updated_at: :desc)
  end

  def show
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.player1 = current_user
    @game.current_turn = current_user
    @game.board_state = { state: {} }

    if @game.save
      redirect_to @game, notice: 'Game was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    return redirect_to @game, alert: 'Cannot join this game.' unless @game.waiting? && @game.player1 != current_user

    @game.player2 = current_user
    notice_or_alert = @game.save && @game.start! ? 
      { notice: 'Successfully joined the game.' } :
      { alert: 'Could not join the game.' }
    
    redirect_to @game, notice_or_alert
  end

  def abandon
    return redirect_to @game, alert: 'You cannot abandon this game.' unless @game.player1 == current_user || @game.player2 == current_user
    
    begin
      if @game.save && @game.abandon!
        redirect_to my_games_games_path, notice: 'Game abandoned.'
      else
        redirect_to @game, alert: 'Could not abandon the game.'
      end
    rescue => e
      Rails.logger.error "Game abandon error: #{e.message}"
      redirect_to @game, alert: 'Could not abandon the game.'
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    # We don't actually need any params from the form since we set everything in the controller
    {}
  end
end
