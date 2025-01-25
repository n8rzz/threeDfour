require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'allows a visitor to sign up' do
    visit new_user_registration_path
    
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    
    expect {
      click_button 'Sign up'
    }.to change(User, :count).by(1)
    
    expect(page).to have_content('Welcome')
    expect(User.last.username).to eq('testuser')
  end
end 