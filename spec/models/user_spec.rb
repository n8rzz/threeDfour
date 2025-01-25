require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    context 'when avatar_url is present' do
      it 'validates avatar_url format' do
        user = build(:user, avatar_url: 'not-a-url')
        expect(user).not_to be_valid
        expect(user.errors[:avatar_url]).to include('must be a valid URL')

        user.avatar_url = 'https://example.com/avatar.jpg'
        expect(user).to be_valid
      end
    end

    context 'when avatar_url is blank' do
      it 'is valid' do
        user = build(:user, avatar_url: '')
        expect(user).to be_valid
      end
    end
  end

  describe 'devise modules' do
    it { should validate_presence_of(:password) }
    it { should have_db_column(:sign_in_count).of_type(:integer) }
    it { should have_db_column(:current_sign_in_at).of_type(:datetime) }
    it { should have_db_column(:last_sign_in_at).of_type(:datetime) }
    it { should have_db_column(:current_sign_in_ip).of_type(:string) }
    it { should have_db_column(:last_sign_in_ip).of_type(:string) }
  end
end
