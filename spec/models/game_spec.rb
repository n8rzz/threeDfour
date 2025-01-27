require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'associations' do
    it { should belong_to(:player1).class_name('User') }
    it { should belong_to(:player2).class_name('User').optional }
    it { should belong_to(:current_turn).class_name('User') }
    it { should belong_to(:winner).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:board_state) }

    context 'when game is in_progress' do
      subject { build(:game, status: 'in_progress') }

      it 'requires player2' do
        expect(subject).not_to be_valid
        expect(subject.errors[:player2]).to include('must be present for in-progress game')
      end
    end

    context 'when setting winner' do
      let(:player1) { create(:user, :confirmed) }
      let(:winner) { create(:user, :confirmed) }

      it 'cannot set winner for waiting game' do
        game = build(:waiting_game, player1: player1, current_turn: player1)
        game.winner = winner
        expect(game).not_to be_valid
        expect(game.errors[:winner]).to include("can't be set unless game is complete with two players")
      end

      it 'cannot set winner for abandoned game' do
        game = build(:abandoned_game, player1: player1, current_turn: player1)
        game.winner = winner
        expect(game).not_to be_valid
        expect(game.errors[:winner]).to include("can't be set unless game is complete with two players")
      end

      it 'cannot set winner without player2' do
        game = build(:game, status: 'complete', player1: player1, current_turn: player1)
        game.winner = winner
        expect(game).not_to be_valid
        expect(game.errors[:winner]).to include("can't be set unless game is complete with two players")
      end
    end

    context 'when validating current_turn' do
      let(:player1) { create(:user, :confirmed) }
      let(:other_player) { create(:user, :confirmed) }

      it 'requires current_turn to be player1 when waiting' do
        game = build(:waiting_game, player1: player1)
        game.current_turn = other_player
        expect(game).not_to be_valid
        expect(game.errors[:current_turn]).to include('must be player1 when not in progress')
      end

      it 'requires current_turn to be one of the players when in progress' do
        game = build(:in_progress_game, player1: player1)
        game.current_turn = other_player
        expect(game).not_to be_valid
        expect(game.errors[:current_turn]).to include('must be one of the players')
      end
    end
  end

  describe 'state transitions' do
    let(:player1) { create(:user, :confirmed) }
    let(:player2) { create(:user, :confirmed) }
    let(:game) { create(:waiting_game, player1: player1, current_turn: player1) }

    it 'starts game when player2 joins' do
      game.player2 = player2
      expect(game.start).to be true
      expect(game).to be_in_progress
    end

    it 'cannot start game without player2' do
      expect { game.start! }.to raise_error(AASM::InvalidTransition)
      expect(game).to be_waiting
    end

    it 'can be abandoned from waiting' do
      expect(game.abandon).to be true
      expect(game).to be_abandoned
    end

    it 'can be abandoned from in_progress' do
      game.update!(player2: player2)
      game.start
      expect(game.abandon).to be true
      expect(game).to be_abandoned
    end

    it 'can complete from in_progress' do
      game.update!(player2: player2)
      game.start
      expect(game.complete_game).to be true
      expect(game).to be_complete
    end
  end
end
