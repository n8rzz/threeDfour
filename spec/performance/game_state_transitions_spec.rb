require 'rails_helper'

RSpec.describe 'Game State Transitions Performance', :performance do
  let(:player1) { create(:user, :confirmed) }
  let(:player2) { create(:user, :confirmed) }

  def create_game_with_moves(move_count)
    game = create(:in_progress_game, player1: player1, player2: player2, current_turn: player1)
    
    (move_count / 2).times do
      create(:game_move, game: game, user: player1)

      game.update!(current_turn: player2)
      
      create(:game_move, game: game, user: player2)

      game.update!(current_turn: player1)
    end

    game
  end

  it 'handles rapid state transitions efficiently' do
    games = 10.times.map { create(:waiting_game, player1: player1, current_turn: player1) }
    memory_before = GetProcessMem.new.mb
    
    time = Benchmark.measure do
      games.each do |game|
        game.update!(player2: player2)
        game.start!

        create(:game_move, game: game, user: player1)

        game.update!(current_turn: player2)
        
        create(:game_move, game: game, user: player2)

        game.complete_game!
      end
    end

    memory_after = GetProcessMem.new.mb

    puts "\nState transition performance (10 games):"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Average time per game: #{(time.real / 10).round(3)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real / 10).to be < 0.1
    expect(memory_after - memory_before).to be < 10
  end

  it 'maintains performance with increasing move counts during completion' do
    move_counts = [10, 50, 100]
    timings = {}

    move_counts.each do |count|
      game = create_game_with_moves(count)

      time = Benchmark.measure do
        game.complete_game!
      end

      timings[count] = time

      puts "\nGame completion - Move count: #{count}"
      puts "Total time: #{time.real.round(3)} seconds"
      puts "Time per move: #{(time.real / count).round(5)} seconds"
    end

    previous_time = 0

    timings.each do |count, timing|
      if previous_time > 0
        expect(timing.real).to be < (previous_time * 2.5)
      end

      previous_time = timing.real
    end
  end

  it 'handles concurrent state transitions efficiently', :skip_in_ci do
    games = 5.times.map do
      create_game_with_moves(20)
    end

    threads = []
    mutex = Mutex.new
    memory_before = GetProcessMem.new.mb

    time = Benchmark.measure do
      games.each do |game|
        threads << Thread.new do
          mutex.synchronize do
            game.complete_game!
          end
        end
      end
      threads.each(&:join)
    end

    memory_after = GetProcessMem.new.mb

    puts "\nConcurrent game completion (5 games, 20 moves each):"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Average time per game: #{(time.real / 5).round(3)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real / 5).to be < 0.2 
    expect(memory_after - memory_before).to be < 15
  end

  it 'maintains reasonable memory usage during abandonment' do
    game = create_game_with_moves(200)
    memory_before = GetProcessMem.new.mb

    time = Benchmark.measure do
      game.abandon!
    end

    memory_after = GetProcessMem.new.mb

    puts "\nGame abandonment (200 moves):"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real).to be < 0.5
    expect(memory_after - memory_before).to be < 10
  end
end 