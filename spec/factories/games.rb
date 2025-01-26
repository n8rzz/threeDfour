FactoryBot.define do
  factory :game do
    association :player1, factory: [:user, :confirmed]
    association :current_turn, factory: [:user, :confirmed]

    trait :waiting do
      status { 'waiting' }
      after(:build) do |game|
        game.current_turn = game.player1
      end
    end

    trait :in_progress do
      status { 'in_progress' }
      association :player2, factory: [:user, :confirmed]
      after(:build) do |game|
        game.current_turn = [game.player1, game.player2].sample
      end
    end

    trait :complete do
      status { 'complete' }
      association :player2, factory: [:user, :confirmed]
      association :winner, factory: [:user, :confirmed]
      after(:build) do |game|
        game.winner = [game.player1, game.player2].sample
      end
    end

    trait :abandoned do
      status { 'abandoned' }
    end

    factory :waiting_game, traits: [:waiting]
    factory :in_progress_game, traits: [:in_progress]
    factory :complete_game, traits: [:complete]
    factory :abandoned_game, traits: [:abandoned]
  end
end
