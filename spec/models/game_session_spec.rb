require 'rails_helper'

RSpec.describe GameSession, type: :model do
  describe 'associations' do
    it { should belong_to(:game) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:session_id) }

    it 'validates uniqueness of session_id' do
      create(:game_session)
      should validate_uniqueness_of(:session_id)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:game_session)).to be_valid
    end

    it 'generates unique session_ids' do
      session1 = create(:game_session)
      session2 = create(:game_session)
      expect(session1.session_id).not_to eq(session2.session_id)
    end
  end
end
