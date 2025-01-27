class AddLastSeenAtToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :last_seen_at, :datetime
  end
end
