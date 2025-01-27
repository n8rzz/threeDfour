require 'rails_helper'

RSpec.describe GameChannel, type: :channel do
  describe '#subscribed' do
    context 'with valid game_id' do
      it 'subscribes to the correct stream' do
        stub_connection
        subscribe(game_id: 1)
        
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("game_1")
      end
    end

    context 'with missing game_id' do
      it 'does not subscribe to any stream' do
        stub_connection
        subscribe(game_id: nil)
        
        expect(subscription).to be_confirmed
        expect(subscription.streams).to be_empty
      end
    end

    # TODO: Add tests for authorization rules
    # it 'rejects subscription when user is not authorized to view the game'
  end

  describe '#receive' do
    it 'returns early when game is not found' do
      stub_connection
      subscribe(game_id: 1)
      
      expect(Game).to receive(:find).with("123").and_return(nil)
      expect(ActionCable.server).not_to receive(:broadcast)
      
      perform :receive, { 'game_id' => '123', 'user_id' => 1, 'move' => 'some_move' }
    end

    # TODO: Add tests for valid moves
    # it 'broadcasts the move when it is valid'

    # TODO: Add tests for invalid moves
    # it 'handles invalid moves appropriately'

    # TODO: Add tests for user validation
    # it 'validates user permissions before broadcasting'
  end

  describe '#unsubscribed' do
    it 'clears all streams' do
      stub_connection
      subscribe(game_id: 1)
      
      expect(subscription.streams).not_to be_empty
      subscription.unsubscribe_from_channel
      expect(subscription.streams).to be_empty
    end
  end
end
