require 'rails_helper'

RSpec.describe 'User authentication', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'sign up' do
    it 'allows new users to register with valid information' do
      visit new_user_registration_path
      
      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Username', with: 'newuser'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      
      expect {
        click_button 'Sign up'
      }.to change(User, :count).by(1)
      
      expect(page).to have_content('Welcome')
      expect(User.last.username).to eq('newuser')
    end

    it 'shows validation errors with invalid information' do
      visit new_user_registration_path
      click_button 'Sign up'
      
      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Username can't be blank")
      expect(page).to have_content("Password can't be blank")
    end
  end

  describe 'sign in' do
    let!(:user) { create(:user, password: 'password123') }

    it 'allows users to sign in with valid credentials' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      
      expect(page).to have_content('Signed in successfully')
    end

    it 'shows error with invalid credentials' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Log in'
      
      expect(page).to have_content('Invalid Email or password')
    end
  end

  describe 'password reset' do
    let!(:user) { create(:user) }

    it 'allows users to request password reset' do
      visit new_user_password_path
      
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'
      
      expect(page).to have_content('You will receive an email with instructions')
      expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
    end
  end

  describe 'sign out' do
    let!(:user) { create(:user) }

    it 'allows signed in users to sign out' do
      sign_in user
      visit root_path
      
      click_link 'Sign out'
      expect(page).to have_content('Signed out successfully')
    end
  end
end 