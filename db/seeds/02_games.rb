puts 'Creating games...'

admin = User.find_by(email: 'starship@example.com')
user = User.find_by(email: 'user@example.com')
pending = User.find_by(email: 'pending@example.com')

# Game in waiting state (available to join)
waiting = Game.find_or_initialize_by(
  player1: admin,
  status: 'waiting'
)
unless waiting.persisted?
  waiting.current_turn = admin
  waiting.save!
end

# Game in progress
in_progress = Game.find_or_initialize_by(
  player1: admin,
  player2: user,
  status: 'in_progress'
)
unless in_progress.persisted?
  in_progress.current_turn = user
  in_progress.save!
end

# Completed game with winner
completed = Game.find_or_initialize_by(
  player1: user,
  player2: admin,
  winner: admin,
  status: 'complete'
)
unless completed.persisted?
  completed.current_turn = user
  completed.save!
end

# Abandoned game from waiting state
abandoned_waiting = Game.find_or_initialize_by(
  player1: user,
  status: 'abandoned',
  player2: nil
)
unless abandoned_waiting.persisted?
  abandoned_waiting.current_turn = user
  abandoned_waiting.save!
end

# Abandoned game from in_progress state
abandoned_playing = Game.find_or_initialize_by(
  player1: admin,
  player2: user,
  status: 'abandoned'
)
unless abandoned_playing.persisted?
  abandoned_playing.current_turn = admin
  abandoned_playing.save!
end

puts 'Finished creating games'
