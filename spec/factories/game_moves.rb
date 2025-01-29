FactoryBot.define do
  factory :game_move do
    association :game, factory: :in_progress_game
    level { rand(0..3) }
    column { rand(0..3) }
    row { rand(0..3) }

    after(:build) do |game_move|
      # Ensure the user is a participant and it's their turn
      game_move.user ||= game_move.game.current_turn
    end

    trait :valid_move do
      is_valid { true }
    end

    trait :invalid_move do
      is_valid { false }
    end
  end
end 