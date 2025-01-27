# Create game sessions for existing games
puts 'Creating game sessions...'

Game.find_each do |game|
  # Create a session for player1
  GameSession.create!(
    game: game,
    user: game.player1,
    session_id: "ws_#{SecureRandom.hex(8)}_p1_#{game.id}"
  )

  # Create a session for player2 if they exist
  if game.player2.present?
    GameSession.create!(
      game: game,
      user: game.player2,
      session_id: "ws_#{SecureRandom.hex(8)}_p2_#{game.id}"
    )
  end
end

puts "Created #{GameSession.count} game sessions"
