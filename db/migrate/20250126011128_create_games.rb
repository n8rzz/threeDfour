class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :status, null: false, default: 'waiting'
      t.references :player1, null: false, foreign_key: { to_table: :users }
      t.references :player2, foreign_key: { to_table: :users }
      t.references :current_turn, null: false, foreign_key: { to_table: :users }
      t.json :board_state, null: false, default: { state: {} }
      t.references :winner, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
