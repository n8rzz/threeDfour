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

    context 'with boundary values' do
      let(:game) { create(:in_progress_game) }
      let(:user) { game.current_turn }

      before do
        game.update!(current_turn: user)
      end

      it 'is invalid with negative values' do
        game_move = build(:game_move, game: game, user: user,
                         level: -1, column: -1, row: -1)
        expect(game_move).to be_invalid
        expect(game_move.errors[:level]).to include("must be greater than or equal to 0")
        expect(game_move.errors[:column]).to include("must be greater than or equal to 0")
        expect(game_move.errors[:row]).to include("must be greater than or equal to 0")
      end

      it 'is invalid with values > 3' do
        game_move = build(:game_move, game: game, user: user,
                         level: 4, column: 4, row: 4)
        expect(game_move).to be_invalid
        expect(game_move.errors[:level]).to include("must be less than 4")
        expect(game_move.errors[:column]).to include("must be less than 4")
        expect(game_move.errors[:row]).to include("must be less than 4")
      end

      it 'is valid with values = 0' do
        game_move = build(:game_move, game: game, user: user,
                         level: 0, column: 0, row: 0)
        expect(game_move).to be_valid
      end

      it 'is valid with values = 3' do
        game_move = build(:game_move, game: game, user: user,
                         level: 3, column: 3, row: 3)
        expect(game_move).to be_valid
      end
    end

    context 'when move overlaps with existing move' do
      let(:game) { create(:in_progress_game) }
      let(:user) { game.current_turn }
      let!(:existing_move) do
        create(:game_move, game: game, user: user,
               level: 1, column: 1, row: 1, is_valid: true)
      end

      before do
        game.board_state[1][1][1] = 1
        game.save!
        game.update!(current_turn: game.player2)
      end

      it 'is invalid when position is already taken' do
        new_move = build(:game_move, game: game, user: game.current_turn,
                        level: 1, column: 1, row: 1)
        
                        expect(new_move).to be_invalid
        expect(new_move.errors[:base]).to include("Position is already taken")
      end

      it 'is valid when position is empty' do
        new_move = build(:game_move, game: game, user: game.current_turn,
                        level: 0, column: 0, row: 0)
        
                        expect(new_move).to be_valid
      end

      it 'updates board state when move is valid' do
        move_data = [0, 0, 0]
        result = GameMoveProcessor.new(game, game.current_turn).process(move_data)
        
        expect(result[:success]).to be true
        
        game.reload
        expect(game.board_state[0][0][0]).to eq(2)
      end
    end
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