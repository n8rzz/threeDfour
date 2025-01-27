FactoryBot.define do
  factory :game_session do
    association :game, factory: [ :game, :waiting ]
    association :user
    sequence(:session_id) { |n| "ws_#{SecureRandom.hex(8)}_#{n}" }

    after(:build) do |game_session|
      game_session.user = game_session.game.player1 if game_session.user.nil?
    end
  end
end
