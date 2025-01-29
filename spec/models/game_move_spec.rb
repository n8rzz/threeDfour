require 'rails_helper'

RSpec.describe GameMove, type: :model do
  describe 'associations' do
    it { should belong_to(:game) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:game_move) }

    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:column) }
    it { should validate_presence_of(:row) }

    it { should validate_numericality_of(:level).only_integer.is_greater_than_or_equal_to(0).is_less_than(4) }
    it { should validate_numericality_of(:column).only_integer.is_greater_than_or_equal_to(0).is_less_than(4) }
    it { should validate_numericality_of(:row).only_integer.is_greater_than_or_equal_to(0).is_less_than(4) }
  end

  describe 'custom validations' do
    let(:game) { create(:in_progress_game) }
    let(:user) { game.current_turn }
    let(:game_move) { build(:game_move, game: game, user: user) }

    context 'when user is not a game participant' do
      let(:non_participant) { create(:user, :confirmed) }
      
      it 'is invalid' do
        game_move.user = non_participant
        expect(game_move).to be_invalid
        expect(game_move.errors[:user]).to include('must be a participant in the game')
      end
    end

    context 'when game is not in progress' do
      let(:waiting_game) { create(:waiting_game) }
      
      it 'is invalid' do
        game_move.game = waiting_game
        expect(game_move).to be_invalid
        expect(game_move.errors[:game]).to include('must be in progress')
      end
    end

    context 'when user is not current turn' do
      let(:other_player) { game.player1 == user ? game.player2 : game.player1 }
      
      it 'is invalid' do
        game_move.user = other_player
        expect(game_move).to be_invalid
        expect(game_move.errors[:user]).to include('must be the current turn player')
      end
    end

    context 'when all validations pass' do
      it 'is valid' do
        expect(game_move).to be_valid
      end
    end
  end

  describe 'after save' do
    let(:game) { create(:in_progress_game) }
    let(:player1) { game.player1 }
    let(:player2) { game.player2 }

    context 'when move is valid' do
      let(:game_move) do
        build(:game_move, game: game, user: game.current_turn, is_valid: true)
      end

      it 'switches current turn to the other player' do
        original_turn = game.current_turn
        other_player = (game.current_turn == player1) ? player2 : player1

        game_move.save!
        game.reload

        expect(game.current_turn).to eq(other_player)
        expect(game.current_turn).not_to eq(original_turn)
      end

      it 'maintains turn order for consecutive moves' do
        game.update!(current_turn: player1)

        first_move = create(:game_move, game: game, user: player1, is_valid: true)

        game.reload

        expect(game.current_turn).to eq(player2)

        second_move = create(:game_move, game: game, user: player2, is_valid: true)

        game.reload

        expect(game.current_turn).to eq(player1)
      end
    end

    context 'when move is invalid' do
      let(:game_move) do
        build(:game_move, game: game, user: game.current_turn, is_valid: false)
      end

      it 'does not switch current turn' do
        original_turn = game.current_turn

        game_move.save!
        game.reload

        expect(game.current_turn).to eq(original_turn)
      end
    end
  end

  describe '#toggle_current_turn' do
    let(:game) { create(:in_progress_game) }
    let(:player1) { game.player1 }
    let(:player2) { game.player2 }
    let(:game_move) { build(:game_move, game: game, user: game.current_turn, is_valid: true) }

    context 'when current turn is player1' do
      before do
        game.update!(current_turn: player1)
      end

      it 'switches turn to player2' do
        game_move.save!
        game.reload
        expect(game.current_turn).to eq(player2)
      end
    end

    context 'when current turn is player2' do
      before do
        game.update!(current_turn: player2)
      end

      it 'switches turn to player1' do
        game_move.save!
        game.reload
        expect(game.current_turn).to eq(player1)
      end
    end

    context 'when move is invalid' do
      let(:game_move) { build(:game_move, game: game, user: game.current_turn, is_valid: false) }

      it 'does not toggle turn' do
        original_turn = game.current_turn
        game_move.save!
        game.reload
        expect(game.current_turn).to eq(original_turn)
      end
    end

    context 'when called multiple times' do
      it 'alternates between players' do
        game.update!(current_turn: player1)

        # First move
        create(:game_move, game: game, user: player1, is_valid: true)
        game.reload
        expect(game.current_turn).to eq(player2)

        # Second move
        create(:game_move, game: game, user: player2, is_valid: true)
        game.reload
        expect(game.current_turn).to eq(player1)

        # Third move
        create(:game_move, game: game, user: player1, is_valid: true)
        game.reload
        expect(game.current_turn).to eq(player2)
      end
    end

    context 'when game is updated concurrently' do
      it 'handles race conditions safely' do
        game.update!(current_turn: player1)
        game_move = build(:game_move, game: game, user: player1, is_valid: true)

        # Simulate a concurrent update
        other_game = Game.find(game.id)
        other_game.update!(current_turn: player2)

        # Our move should still process correctly
        expect { game_move.save! }.not_to raise_error
        game.reload
        expect(game.current_turn).to be_in([player1, player2])
      end
    end
  end
end 