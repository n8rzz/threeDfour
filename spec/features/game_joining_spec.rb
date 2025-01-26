require 'rails_helper'

RSpec.describe 'Game Joining', type: :system do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let!(:available_game) { create(:waiting_game, player1: other_user) }
  let!(:my_game) { create(:waiting_game, player1: user) }
  
  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it 'shows available games and allows joining them' do
    visit games_path
    
    # Should see the available game but not our own game
    expect(page).to have_content(other_user.username)
    expect(page).not_to have_content("Created by: #{user.username}")
    
    # Disable Turbo for the form and submit it
    page.execute_script('document.querySelector("form[action$=\'/join\']").setAttribute("data-turbo", "false")')
    click_button 'Join Game'
    
    # Wait for and verify success
    expect(page).to have_current_path(game_path(available_game), wait: 5)
    expect(page).to have_content('Successfully joined the game.')
    
    # Verify game state was updated
    available_game.reload
    expect(available_game.player2).to eq(user)
    expect(available_game.status).to eq('in_progress')
  end

  it 'does not show games that are already in progress' do
    in_progress_game = create(:in_progress_game, player1: other_user)
    
    visit games_path
    
    expect(page).to have_content(other_user.username)
    expect(page).not_to have_content(in_progress_game.player2.username)
  end
end 