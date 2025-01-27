require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }

  before do
    sign_in user
  end

  describe "GET /games" do
    it "shows available games" do
      waiting_game = create(:waiting_game, player1: other_user, current_turn: other_user)
      my_waiting_game = create(:waiting_game, player1: user, current_turn: user)
      in_progress_game = create(:in_progress_game)

      get games_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(waiting_game.player1.username)
      expect(response.body).not_to include(my_waiting_game.player1.username)
      expect(response.body).not_to include(in_progress_game.player1.username)
    end
  end

  describe "GET /games/:id" do
    it "shows the game details" do
      game = create(:waiting_game, player1: user, current_turn: user)

      get game_path(game)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(game.player1.username)
      expect(response.body).to include('Waiting')
    end

    it "shows both players for in-progress games" do
      game = create(:in_progress_game, player1: user, player2: other_user)

      get game_path(game)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(game.player1.username)
      expect(response.body).to include(game.player2.username)
      expect(response.body).to include('In Progress')
    end
  end

  describe "GET /games/new" do
    it "shows the new game form" do
      get new_game_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('New Game')
    end
  end

  describe "POST /games" do
    it "creates a new game" do
      expect {
        post games_path, params: { game: { board_state: { state: {} } } }
      }.to change(Game, :count).by(1)

      game = Game.last
      expect(game.player1).to eq(user)
      expect(game.current_turn).to eq(user)
      expect(game).to be_waiting
      expect(response).to redirect_to(game_path(game))
    end
  end

  describe "GET /games/my_games" do
    it "shows games where user is player1 or player2" do
      my_game1 = create(:waiting_game, player1: user, current_turn: user)

      other_player = create(:user, :confirmed)
      my_game2 = create(:in_progress_game, player1: other_player, player2: user, current_turn: other_player)

      another_player = create(:user, :confirmed)
      other_game = create(:waiting_game, player1: another_player, current_turn: another_player)

      get my_games_games_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(my_game1.player1.username)
      expect(response.body).to include(my_game2.player2.username)
      expect(response.body).not_to include(other_game.player1.username)
    end
  end

  describe "PATCH /games/:id/join" do
    let(:game) { create(:waiting_game, player1: other_user, current_turn: other_user) }

    it "allows joining an available game" do
      patch join_game_path(game)
      expect(game.reload.player2).to eq(user)
      expect(game).to be_in_progress
      expect(response).to redirect_to(game_path(game))
    end

    it "prevents joining your own game" do
      game.update!(player1: user, current_turn: user)
      patch join_game_path(game)
      expect(game.reload.player2).to be_nil
      expect(game).to be_waiting
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to be_present
    end

    it "prevents joining a non-waiting game" do
      game.update!(status: :in_progress, player2: create(:user, :confirmed))
      patch join_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /games/:id/abandon" do
    context "when user is player1" do
      context "with a waiting game" do
        let(:game) { create(:waiting_game, player1: user, current_turn: user) }

        it "allows abandoning the game" do
          patch abandon_game_path(game)
          expect(game.reload).to be_abandoned
          expect(response).to redirect_to(my_games_games_path)
        end
      end

      context "with an in-progress game" do
        let(:game) { create(:in_progress_game, player1: user, player2: other_user) }

        it "allows abandoning the game" do
          patch abandon_game_path(game)
          expect(game.reload).to be_abandoned
          expect(response).to redirect_to(my_games_games_path)
        end
      end
    end

    context "when user is player2" do
      let(:game) { create(:in_progress_game, player1: other_user, player2: user, current_turn: other_user) }

      it "allows abandoning the game" do
        patch abandon_game_path(game)
        expect(game.reload).to be_abandoned
        expect(response).to redirect_to(my_games_games_path)
      end
    end

    context "when user is not a player" do
      let(:game) { create(:waiting_game, player1: other_user, current_turn: other_user) }

      it "prevents abandoning the game" do
        patch abandon_game_path(game)
        expect(game.reload).to be_waiting
        expect(response).to redirect_to(game_path(game))
        expect(flash[:alert]).to be_present
      end
    end
  end

  context "when not signed in" do
    before do
      sign_out user
    end

    it "redirects to sign in" do
      get games_path
      expect(response).to redirect_to(new_user_session_path)

      get new_game_path
      expect(response).to redirect_to(new_user_session_path)

      get my_games_games_path
      expect(response).to redirect_to(new_user_session_path)

      post games_path
      expect(response).to redirect_to(new_user_session_path)

      game = create(:waiting_game)
      patch join_game_path(game)
      expect(response).to redirect_to(new_user_session_path)

      patch abandon_game_path(game)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
