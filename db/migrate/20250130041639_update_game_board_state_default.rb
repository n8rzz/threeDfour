class UpdateGameBoardStateDefault < ActiveRecord::Migration[8.0]
  def up
    default_board_state = Array.new(4) { Array.new(4) { Array.new(4, -1) } }
    
    change_column_default :games, :board_state, default_board_state
  end

  def down
    change_column_default :games, :board_state, { "state" => {} }
  end
end
