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
end 