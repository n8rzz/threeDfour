class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :join, :abandon]

  def index
    @games = Game.available_to_join(current_user)
  end

  def my_games
    @games = Game.for_user(current_user).by_recent
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
      redirect_with_success(@game, 'Game was successfully created.')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    return redirect_with_error(@game, 'Game is not available to join.') unless can_join_game?

    @game.player2 = current_user
    
    if @game.save && @game.start!
      redirect_with_success(@game, 'Successfully joined the game.')
    else
      error_message = join_error_message
      redirect_with_error(@game, error_message)
    end
  rescue AASM::InvalidTransition
    redirect_with_error(@game, 'Game cannot be started.')
  end

  def abandon
    return redirect_with_error(game_path(@game), 'You cannot abandon this game.') unless can_abandon_game?

    if @game.abandon!
      redirect_with_success(my_games_games_path, 'Game abandoned.')
    else
      redirect_with_error(my_games_games_path, 'Could not abandon the game.')
    end
  rescue => e
    Rails.logger.error "Game abandon error: #{e.message}"
    redirect_with_error(my_games_games_path, 'Could not abandon the game.')
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    {}
  end

  def can_join_game?
    @game.waiting? && @game.player1 != current_user
  end

  def can_abandon_game?
    return false unless @game.waiting? || @game.in_progress?
    @game.player1 == current_user || @game.player2 == current_user
  end

  def join_error_message
    if @game.errors[:player2].any?
      'Could not join as player 2.'
    elsif @game.errors[:current_turn].any?
      'Invalid turn state for game.'
    else
      'Could not join the game.'
    end
  end

  def redirect_with_success(path, message)
    respond_to do |format|
      format.html { redirect_to path, notice: message }
      format.turbo_stream { redirect_to path, notice: message }
    end
  end

  def redirect_with_error(path, message)
    respond_to do |format|
      format.html { redirect_to path, alert: message }
      format.turbo_stream { redirect_to path, alert: message }
    end
  end
end
