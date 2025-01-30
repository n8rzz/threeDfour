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

  describe 'move history serialization' do
    let(:player1) { create(:user, :confirmed) }
    let(:player2) { create(:user, :confirmed) }
    let(:game) { create(:in_progress_game, player1: player1, player2: player2, current_turn: player1) }

    context 'when game has moves' do
      before do
        travel_to(1.hour.ago) do
          create(:game_move, game: game, user: player1, level: 0, column: 1, row: 1, is_valid: true)
        end

        travel_to(30.minutes.ago) do
          game.update!(current_turn: player2)
          create(:game_move, game: game, user: player2, level: 1, column: 2, row: 2, is_valid: true)
        end

        travel_to(15.minutes.ago) do
          game.update!(current_turn: player1)
          create(:game_move, game: game, user: player1, level: 2, column: 0, row: 0, is_valid: false)
        end
      end

      context 'when game is completed' do
        it 'serializes move history in chronological order' do
          game.complete_game!
          game.reload

          expect(game.move_history).to be_an(Array)
          expect(game.move_history.length).to eq(3)
          
          first_move = game.move_history[0]
          expect(first_move['user_id']).to eq(player1.id)
          expect(first_move['level']).to eq(0)
          expect(first_move['column']).to eq(1)
          expect(first_move['row']).to eq(1)
          expect(first_move['is_valid']).to be true
          expect(first_move['created_at']).to be_present

          second_move = game.move_history[1]
          expect(second_move['user_id']).to eq(player2.id)
          expect(second_move['is_valid']).to be true

          third_move = game.move_history[2]
          expect(third_move['user_id']).to eq(player1.id)
          expect(third_move['is_valid']).to be false

          move_times = game.move_history.map { |m| Time.parse(m['created_at']) }
          expect(move_times).to eq(move_times.sort)
        end
      end

      context 'when game is abandoned' do
        it 'serializes move history and sets current turn to player1' do
          game.abandon!
          game.reload

          expect(game.move_history).to be_an(Array)
          expect(game.move_history.length).to eq(3)
          expect(game.current_turn).to eq(player1)
        end
      end
    end

    context 'when game has no moves' do
      let(:empty_game) { create(:in_progress_game, player1: player1, player2: player2, current_turn: player1) }

      it 'does not serialize anything when completed' do
        empty_game.complete_game!
        empty_game.reload

        expect(empty_game.move_history).to be_nil
      end

      it 'does not serialize anything when abandoned' do
        empty_game.abandon!
        empty_game.reload

        expect(empty_game.move_history).to be_nil
      end
    end

    context 'edge cases' do
      let(:game_with_many_moves) { create(:in_progress_game, player1: player1, player2: player2, current_turn: player1) }
      
      it 'handles a game with many moves efficiently' do
        50.times do |i|
          travel_to(i.minutes.ago) do
            create(:game_move, game: game_with_many_moves, user: player1, level: rand(0..3), column: rand(0..3), row: rand(0..3))
            
            game_with_many_moves.update!(current_turn: player2)
            
            create(:game_move, game: game_with_many_moves, user: player2, level: rand(0..3), column: rand(0..3), row: rand(0..3))
            
            game_with_many_moves.update!(current_turn: player1)
          end
        end

        game_with_many_moves.complete_game!
        game_with_many_moves.reload
        expect(game_with_many_moves.move_history.length).to eq(100)
      end

      it 'handles moves with identical timestamps' do
        travel_to(Time.current) do
          create(:game_move, game: game, user: player1, level: 0, column: 0, row: 0)
          
          game.update!(current_turn: player2)
          
          create(:game_move, game: game, user: player2, level: 1, column: 1, row: 1)
        end

        game.complete_game!
        game.reload

        expect(game.move_history.map { |m| m['user_id'] }).to eq([player1.id, player2.id])
      end

      it 'handles moves with minimal valid values' do
        create(:game_move, game: game, user: player1, level: 0, column: 0, row: 0)

        expect(game.complete_game).to be true
        game.reload

        expect(game.move_history).to be_an(Array)
        serialized_move = game.move_history.first
        expect(serialized_move['level']).to eq(0)
        expect(serialized_move['column']).to eq(0)
        expect(serialized_move['row']).to eq(0)
        expect(serialized_move['user_id']).to eq(player1.id)
        expect(serialized_move['is_valid']).to be true
      end

      it 'prevents moves after game completion' do
        expect(game).to be_in_progress

        expect(game.complete_game).to be true

        game.reload

        expect(game.status).to eq('complete')
        expect(game).to be_complete
        expect(game).not_to be_in_progress

        expect {
          create(:game_move, game: game, user: player1, level: 0, column: 0, row: 0)
        }.to raise_error(ActiveRecord::RecordInvalid, /Game must be in progress/)
      end
    end
  end
end
