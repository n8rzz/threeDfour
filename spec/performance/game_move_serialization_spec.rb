require 'rails_helper'

RSpec.describe 'Game Move Serialization Performance', :performance do
  let(:player1) { create(:user, :confirmed) }
  let(:player2) { create(:user, :confirmed) }
  let(:game) { create(:in_progress_game, player1: player1, player2: player2, current_turn: player1) }

  def create_moves(game, count)
    (count / 2).times do
      create(:game_move, game: game, user: player1)

      game.update!(current_turn: player2)

      create(:game_move, game: game, user: player2)

      game.update!(current_turn: player1)
    end
  end

  it 'maintains reasonable performance with increasing move counts' do
    move_counts = [ 10, 50, 100 ]
    timings = {}

    move_counts.each do |count|
      game.game_moves.destroy_all
      game.update_columns(status: 'in_progress', move_history: nil)

      create_moves(game, count)

      timings[count] = Benchmark.measure do
        game.complete_game!
        game.reload
      end

      puts "\nMove count: #{count}"
      puts "Real time: #{timings[count].real}"
      puts "System time: #{timings[count].stime}"
      puts "User time: #{timings[count].utime}"
    end

    previous_time = 0

    timings.each do |count, timing|
      if previous_time > 0
        expect(timing.real).to be < (previous_time * 2.5)
      end

      previous_time = timing.real
    end
  end

  it 'handles memory usage efficiently with large move counts' do
    create_moves(game, 200)

    memory_before = GetProcessMem.new.mb

    game.complete_game!

    memory_after = GetProcessMem.new.mb

    puts "\nMemory usage:"
    puts "Before: #{memory_before.round(2)} MB"
    puts "After: #{memory_after.round(2)} MB"
    puts "Difference: #{(memory_after - memory_before).round(2)} MB"

    expect(memory_after - memory_before).to be < 10
  end

  it 'handles batch serialization efficiently', :skip_in_ci do
    games = 5.times.map do
      game = create(:in_progress_game, player1: player1, player2: player2, current_turn: player1)

      create_moves(game, 50)
      game
    end

    memory_before = GetProcessMem.new.mb

    time = Benchmark.measure do
      games.each(&:complete_game!)
    end

    memory_after = GetProcessMem.new.mb

    puts "\nBatch serialization (5 games, 50 moves each):"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Average time per game: #{(time.real / 5).round(3)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real).to be < 1.0
    expect(memory_after - memory_before).to be < 20
  end
end
