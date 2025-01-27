require 'rails_helper'

RSpec.describe 'Game Creation', type: :system do
  let(:user) { create(:user, :confirmed) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
    puts "Current user signed in: #{user.email}"
  end

  it 'allows a user to create a new game' do
    visit new_game_path

    # Since we don't have any form fields yet, just click create
    click_button 'Create Game'

    expect(page).to have_content('Game was successfully created.')
    expect(page).to have_current_path(game_path(Game.last))

    game = Game.last
    expect(game.player1).to eq(user)
    expect(game.current_turn).to eq(user)
    expect(game.status).to eq('waiting')
  end
end
