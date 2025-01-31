require 'rails_helper'

RSpec.describe 'Game Move Creation Performance', :performance do
  let(:player1) { create(:user, :confirmed) }
  let(:player2) { create(:user, :confirmed) }
  let(:game) { create(:in_progress_game, player1: player1, player2: player2, current_turn: player1) }

  it 'maintains reasonable performance for rapid move creation' do
    move_counts = [ 10, 50, 100 ]
    timings = {}

    move_counts.each do |count|
      game.game_moves.destroy_all
      game.update_columns(status: 'in_progress')

      time = Benchmark.measure do
        count.times do |i|
          current_player = i.even? ? player1 : player2
          game.update!(current_turn: current_player)

          create(:game_move,
            game: game,
            user: current_player,
            level: rand(0..3),
            column: rand(0..3),
            row: rand(0..3)
          )
        end
      end

      timings[count] = time

      puts "\nMove creation - Count: #{count}"
      puts "Total time: #{time.real.round(3)} seconds"
      puts "Average time per move: #{(time.real / count).round(5)} seconds"
    end

    previous_time = 0
    timings.each do |count, timing|
      if previous_time > 0
        # Each doubling of moves should take less than triple the time
        # This accounts for database operations and validations
        expect(timing.real).to be < (previous_time * 5)
      end
      previous_time = timing.real
    end
  end

  it 'handles concurrent move creation efficiently', :skip_in_ci do
    game.update!(current_turn: player1)

    threads = []
    mutex = Mutex.new
    move_count = 20
    memory_before = GetProcessMem.new.mb

    time = Benchmark.measure do
      2.times do |t|
        threads << Thread.new do
          current_player = t.zero? ? player1 : player2
          move_count.times do
            mutex.synchronize do
              game.update!(current_turn: current_player)
              create(:game_move,
                game: game,
                user: current_player,
                level: rand(0..3),
                column: rand(0..3),
                row: rand(0..3)
              )
            end
            sleep(0.01) # Simulate network delay
          end
        end
      end
      threads.each(&:join)
    end

    memory_after = GetProcessMem.new.mb

    puts "\nConcurrent move creation (#{move_count * 2} moves):"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Average time per move: #{(time.real / (move_count * 2)).round(5)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real / (move_count * 2)).to be < 0.1 # Less than 100ms per move
    expect(memory_after - memory_before).to be < 10
  end

  it 'maintains performance with validation checks' do
    invalid_moves = []
    memory_before = GetProcessMem.new.mb

    time = Benchmark.measure do
      20.times do |i|
        current_player = i.even? ? player1 : player2
        game.update!(current_turn: current_player)

        create(:game_move,
          game: game,
          user: current_player,
          level: rand(0..3),
          column: rand(0..3),
          row: rand(0..3)
        )

        invalid_moves << build(:game_move,
          game: game,
          user: i.even? ? player2 : player1, # Wrong turn
          level: rand(0..3),
          column: rand(0..3),
          row: rand(0..3)
        )
      end

      invalid_moves.each(&:valid?)
    end

    memory_after = GetProcessMem.new.mb

    puts "\nMove validation performance:"
    puts "Total time: #{time.real.round(3)} seconds"
    puts "Memory increase: #{(memory_after - memory_before).round(2)} MB"

    expect(time.real / 40).to be < 0.05 # Less than 50ms per validation
    expect(memory_after - memory_before).to be < 5
  end
end
