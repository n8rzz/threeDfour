FactoryBot.define do
  factory :game_move do
    association :game, factory: :in_progress_game
    association :user
    level { rand(0..3) }
    column { rand(0..3) }
    row { rand(0..3) }
    is_valid { true }

    after(:build) do |game_move|
      # Ensure the user is a participant in the game and it's their turn
      if game_move.user && game_move.game
        unless [game_move.game.player1_id, game_move.game.player2_id].include?(game_move.user_id)
          game_move.user = game_move.game.current_turn
        end

        # Always ensure the user is the current turn player
        game_move.game.update!(current_turn: game_move.user) unless game_move.game.current_turn == game_move.user
      end
    end

    trait :valid_move do
      is_valid { true }
    end

    trait :invalid_move do
      is_valid { false }
    end
  end
end 