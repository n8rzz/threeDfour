puts 'Creating users...'

# Admin user - fully confirmed
admin = User.find_or_initialize_by(email: 'starship@example.com')
unless admin.persisted?
  admin.username = 'starship'
  admin.password = 'skyd!ve'
  admin.password_confirmation = 'skyd!ve'
  admin.avatar_url = Faker::Avatar.image
  admin.skip_confirmation! 
  admin.save!
end

player2 = User.find_or_initialize_by(email: 'player2@example.com')
unless player2.persisted?
  player2.username = '2player2'
  player2.password = 'skyd!ve'
  player2.password_confirmation = 'skyd!ve'
  player2.avatar_url = Faker::Avatar.image
  player2.skip_confirmation! 
  player2.save!
end

# Regular confirmed user
user = User.find_or_initialize_by(email: 'user@example.com')
unless user.persisted?
  user.username = Faker::Internet.unique.username(specifier: 5..10)
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.avatar_url = Faker::Avatar.image
  user.skip_confirmation!  # This sets confirmed_at and skips confirmation
  user.save!
end

# Unconfirmed user
pending = User.find_or_initialize_by(email: 'pending@example.com')
unless pending.persisted?
  pending.username = Faker::Internet.unique.username(specifier: 5..10)
  pending.password = 'password123'
  pending.password_confirmation = 'password123'
  pending.avatar_url = Faker::Avatar.image
  pending.skip_confirmation_notification!  # Skip sending confirmation email but leave user unconfirmed
  pending.save!
end

puts 'Finished creating users' 