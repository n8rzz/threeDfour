require 'rails_helper'

RSpec.describe 'Game Abandonment', type: :system do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it 'allows a player to abandon their created game' do
    game = create(:waiting_game, player1: user)
    visit game_path(game)

    expect(page).to have_content(user.username)
    expect(page).to have_content('Player 1')
    expect(page).to have_button('Abandon Game')

    click_button 'Abandon Game'

    # Should be redirected to my games with success message
    expect(page).to have_current_path(my_games_games_path, wait: 5)
    expect(page).to have_content('Game abandoned.')

    # Verify game state
    game.reload
    expect(game.status).to eq('abandoned')
  end

  it 'allows player1 to abandon an in-progress game' do
    game = create(:in_progress_game, player1: user, player2: other_user)
    visit game_path(game)

    expect(page).to have_content(user.username)
    expect(page).to have_content('Player 1')
    expect(page).to have_content(other_user.username)
    expect(page).to have_content('Player 2')
    expect(page).to have_button('Abandon Game')

    click_button 'Abandon Game'

    # Should be redirected to my games with success message
    expect(page).to have_current_path(my_games_games_path, wait: 5)
    expect(page).to have_content('Game abandoned.')

    # Verify game state
    game.reload
    expect(game.status).to eq('abandoned')
  end

  it 'allows a player to abandon a game they joined' do
    game = create(:in_progress_game, player1: other_user, player2: user)
    visit game_path(game)

    expect(page).to have_content(other_user.username)
    expect(page).to have_content('Player 1')
    expect(page).to have_content(user.username)
    expect(page).to have_content('Player 2')
    expect(page).to have_button('Abandon Game')

    click_button 'Abandon Game'

    # Should be redirected to my games with success message
    expect(page).to have_current_path(my_games_games_path, wait: 5)
    expect(page).to have_content('Game abandoned.')

    # Verify game state
    game.reload
    expect(game.status).to eq('abandoned')
  end

  it 'does not allow non-participants to abandon the game' do
    game = create(:in_progress_game, player1: other_user, player2: create(:user, :confirmed))
    visit game_path(game)

    expect(page).to have_content(other_user.username)
    expect(page).to have_content('Player 1')
    expect(page).not_to have_button('Abandon Game')
  end
end
