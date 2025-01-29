require 'rails_helper'

RSpec.describe GameChannel, type: :channel do
  let(:user) { create(:user, :confirmed) }
  let(:game) { create(:in_progress_game, player1: user) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    context 'with valid game_id' do
      it 'subscribes to the correct stream' do
        subscribe(game_id: 1)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("game_1")
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
            "move" => [0, 1, 2]
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
          "move" => [0, 1, 2]
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
              errors: ["User must be the current turn player"]
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
          "move" => [0, 1, 2]
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
          "move" => [0, 1, 2]
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
              errors: ["Game must be in progress"]
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
      subscribe(game_id: 1)

      expect(subscription.streams).not_to be_empty
      subscription.unsubscribe_from_channel
      expect(subscription.streams).to be_empty
    end
  end
end
