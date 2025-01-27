require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it "successfully connects with authenticated user" do
    env = Rack::MockRequest.env_for("/cable", {})
    env["warden"] = double(:warden, user: user)

    connection = described_class.new(ActionCable.server, env)
    expect { connection.connect }.not_to raise_error
    expect(connection.current_user).to eq user
  end

  it "rejects connection without authenticated user" do
    env = Rack::MockRequest.env_for("/cable", {})
    env["warden"] = double(:warden, user: nil)

    connection = described_class.new(ActionCable.server, env)
    expect { connection.connect }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
  end
end 