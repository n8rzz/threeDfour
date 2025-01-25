puts 'Creating users...'

# Admin user - fully confirmed
admin = User.find_or_initialize_by(email: 'admin@example.com')
unless admin.persisted?
  admin.username = 'admin'
  admin.password = 'password123'
  admin.password_confirmation = 'password123'
  admin.avatar_url = 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin'
  admin.skip_confirmation!  # This sets confirmed_at and skips confirmation
  admin.save!
end

# Regular confirmed user
user = User.find_or_initialize_by(email: 'user@example.com')
unless user.persisted?
  user.username = 'regular_user'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.avatar_url = 'https://api.dicebear.com/7.x/avataaars/svg?seed=user'
  user.skip_confirmation!  # This sets confirmed_at and skips confirmation
  user.save!
end

# Unconfirmed user
pending = User.find_or_initialize_by(email: 'pending@example.com')
unless pending.persisted?
  pending.username = 'pending_user'
  pending.password = 'password123'
  pending.password_confirmation = 'password123'
  pending.avatar_url = 'https://api.dicebear.com/7.x/avataaars/svg?seed=pending'
  pending.skip_confirmation_notification!  # Skip sending confirmation email but leave user unconfirmed
  pending.save!
end

puts 'Finished creating users' 