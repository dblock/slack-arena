require 'spec_helper'

describe SlackArena::Server do
  let(:team) { Fabricate(:team) }
  let(:server) { SlackArena::Server.new(team: team) }
  let(:client) { server.send(:client) }

  describe '#channel_joined' do
    it 'sends a welcome message' do
      allow(client).to receive(:self).and_return(Hashie::Mash.new(id: 'U12345'))
      message = 'Welcome to Are.na! Please `/arena connect [channel]` to publish a channel here.'
      expect(client).to receive(:say).with(channel: 'C12345', text: message)
      client.send(:callback, Hashie::Mash.new('channel' => { 'id' => 'C12345' }), :channel_joined)
    end
  end

  context 'hooks' do
    let(:user) { Fabricate(:user, team: team) }

    it 'renames user' do
      client.send(:callback, Hashie::Mash.new(user: { id: user.user_id, name: 'updated' }), :user_change)
      expect(user.reload.user_name).to eq('updated')
    end

    it 'does not touch a user with the same name' do
      expect(User).to receive(:where).and_return([user])
      expect(user).not_to receive(:update_attributes!)
      client.send(:callback, Hashie::Mash.new(user: { id: user.user_id, name: user.user_name }), :user_change)
    end
  end
end
