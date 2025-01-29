class CreateGameMoves < ActiveRecord::Migration[8.0]
  def change
    create_table :game_moves do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :level, null: false
      t.integer :column, null: false
      t.integer :row, null: false
      t.boolean :is_valid, null: false, default: false

      t.timestamps
    end
  end
end
