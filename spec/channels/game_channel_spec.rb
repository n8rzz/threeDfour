require 'rails_helper'

RSpec.describe GameChannel, type: :channel do
  let(:user) { create(:user, :confirmed) }
  let(:game) { create(:in_progress_game, player1: user) }
  let(:game_session) { create(:game_session, game: game, user: user) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    context 'with valid game_id' do
      it 'subscribes to the correct stream' do
        subscribe(game_id: game.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("game_#{game.id}")
      end

      it 'broadcasts player connected status' do
        expect {
          subscribe(game_id: game.id)
        }.to have_broadcasted_to("game_#{game.id}")
          .with(
            hash_including(
              type: "player_status",
              status: "success",
              user_id: user.id,
              connected: true
            )
          )
      end
    end

    context 'with missing game_id' do
      it 'does not subscribe to any stream' do
        subscribe(game_id: nil)

        expect(subscription).to be_confirmed
        expect(subscription.streams).to be_empty
      end
    end

    context 'without authentication' do
      it 'rejects subscription' do
        stub_connection current_user: nil
        subscribe(game_id: 1)
        expect(subscription).to be_rejected
      end
    end

    # TODO: Add tests for authorization rules
    # it 'rejects subscription when user is not authorized to view the game'
  end

  describe '#receive' do
    before do
      subscribe game_id: game.id
    end

    context "when receiving a valid move" do
      before do
        # Ensure it's the user's turn
        game.update!(current_turn: user)
      end

      let(:move_data) do
        {
          "game_id" => game.id,
          "move" => {
            "level" => 0,
            "column" => 1,
            "row" => 2
          }
        }
      end

      it "creates a game move" do
        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move.level).to eq(0)
        expect(game_move.column).to eq(1)
        expect(game_move.row).to eq(2)
        expect(game_move.user).to eq(user)
        expect(game_move).to be_is_valid
      end

      it "broadcasts the move to all players" do
        expect {
          perform :receive, move_data
        }.to have_broadcasted_to("game_#{game.id}")
          .with(
            hash_including(
              type: "move",
              status: "success",
              move: hash_including(
                "level" => 0,
                "column" => 1,
                "row" => 2,
                "user_id" => user.id
              )
            )
          )
      end

      context "when move data is in array format" do
        let(:move_data) do
          {
            "game_id" => game.id,
            "move" => [ 0, 1, 2 ]
          }
        end

        it "correctly converts array format to hash format" do
          expect {
            perform :receive, move_data
          }.to change(GameMove, :count).by(1)

          game_move = GameMove.last
          expect(game_move.level).to eq(0)
          expect(game_move.column).to eq(1)
          expect(game_move.row).to eq(2)
          expect(game_move).to be_is_valid
        end
      end
    end

    context "when it is not the user's turn" do
      before do
        # Ensure it's not the user's turn
        other_player = game.player2
        game.update!(current_turn: other_player)
      end

      let(:move_data) do
        {
          "game_id" => game.id,
          "move" => [ 0, 1, 2 ]
        }
      end

      it "creates an invalid game move" do
        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
        expect(game_move.user).to eq(user) # Ensures server uses current_user
      end

      it "broadcasts an error to the player" do
        expect {
          perform :receive, move_data
        }.to have_broadcasted_to("game_#{game.id}")
          .with(
            hash_including(
              type: "move",
              status: "error",
              errors: [ "User must be the current turn player" ]
            )
          )
      end
    end

    context "when attempting to spoof another user" do
      let(:other_user) { create(:user, :confirmed) }
      let(:move_data) do
        {
          "game_id" => game.id,
          "user_id" => other_user.id, # Attempting to spoof another user
          "move" => [ 0, 1, 2 ]
        }
      end

      it "uses current_user instead of provided user_id" do
        perform :receive, move_data
        game_move = GameMove.last
        expect(game_move.user).to eq(user)
        expect(game_move.user).not_to eq(other_user)
      end
    end

    context "when game is not in progress" do
      let(:waiting_game) { create(:waiting_game, player1: user) }

      before do
        subscribe game_id: waiting_game.id
      end

      let(:move_data) do
        {
          "game_id" => waiting_game.id,
          "move" => [ 0, 1, 2 ]
        }
      end

      it "creates an invalid game move" do
        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
      end

      it "broadcasts an error about game state" do
        expect {
          perform :receive, move_data
        }.to have_broadcasted_to("game_#{waiting_game.id}")
          .with(
            hash_including(
              type: "move",
              status: "error",
              errors: [ "Game must be in progress" ]
            )
          )
      end
    end

    context "when move data is in array format" do
      before do
        game.update!(current_turn: user)
      end

      let(:valid_array_move) do
        {
          "game_id" => game.id,
          "move" => [ 1, 2, 3 ]
        }
      end

      let(:invalid_array_move) do
        {
          "game_id" => game.id,
          "move" => [ 1 ]
        }
      end

      it "correctly converts array format to hash format" do
        expect {
          perform :receive, valid_array_move
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move.level).to eq(1)
        expect(game_move.column).to eq(2)
        expect(game_move.row).to eq(3)
      end

      it "handles arrays with wrong number of elements" do
        expect {
          perform :receive, invalid_array_move
        }.not_to change(GameMove, :count)
      end
    end

    context "when game session is missing" do
      before do
        game_session.destroy
      end

      it "updates last_seen_at but still processes the move" do
        game.update!(current_turn: user)

        expect {
          perform :receive, { "game_id" => game.id, "move" => { "level" => 1, "column" => 1, "row" => 1 } }
        }.to change(GameMove, :count).by(1)
      end
    end

    context "when game_id is invalid" do
      let(:move_data) do
        {
          "game_id" => -1,
          "move" => [ 0, 1, 2 ]
        }
      end

      it "returns early without processing" do
        expect {
          perform :receive, move_data
        }.not_to change(GameMove, :count)
      end
    end

    context "when move data is malformed" do
      before do
        game.update!(current_turn: user)
      end

      it "handles missing level" do
        move_data = {
          "game_id" => game.id,
          "move" => { "column" => 1, "row" => 2 }
        }

        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
      end

      it "handles missing column" do
        move_data = {
          "game_id" => game.id,
          "move" => { "level" => 1, "row" => 2 }
        }

        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
      end

      it "handles missing row" do
        move_data = {
          "game_id" => game.id,
          "move" => { "level" => 1, "column" => 2 }
        }

        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
      end

      it "handles non-numeric values" do
        move_data = {
          "game_id" => game.id,
          "move" => { "level" => "one", "column" => "two", "row" => "three" }
        }

        expect {
          perform :receive, move_data
        }.to change(GameMove, :count).by(1)

        game_move = GameMove.last
        expect(game_move).not_to be_is_valid
      end
    end

    context "with invalid move data" do
      before do
        game.update!(current_turn: user)
      end

      it "broadcasts error for out of bounds move" do
        expect {
          perform :receive, { "game_id" => game.id, "move" => { "level" => 5, "column" => 5, "row" => 5 } }
        }.to have_broadcasted_to("game_#{game.id}").with(
          hash_including(
            type: "move",
            status: "error",
            errors: include("Level must be less than 4")
          )
        )
      end

      it "broadcasts error for missing move coordinates" do
        expect {
          perform :receive, { "game_id" => game.id, "move" => { "level" => 1 } }
        }.to have_broadcasted_to("game_#{game.id}").with(
          hash_including(
            type: "move",
            status: "error",
            errors: include("Column must be greater than or equal to 0", "Row must be greater than or equal to 0")
          )
        )
      end
    end

    # TODO: Add tests for valid moves
    # it 'broadcasts the move when it is valid'

    # TODO: Add tests for invalid moves
    # it 'handles invalid moves appropriately'

    # TODO: Add tests for user validation
    # it 'validates user permissions before broadcasting'
  end

  describe '#unsubscribed' do
    it 'clears all streams' do
      subscribe(game_id: game.id)

      expect(subscription.streams).not_to be_empty
      subscription.unsubscribe_from_channel
      expect(subscription.streams).to be_empty
    end

    it 'broadcasts player disconnected status' do
      subscribe(game_id: game.id)

      expect {
        subscription.unsubscribe_from_channel
      }.to have_broadcasted_to("game_#{game.id}")
        .with(
          hash_including(
            type: "player_status",
            status: "success",
            user_id: user.id,
            connected: false
          )
        )
    end
  end
end
