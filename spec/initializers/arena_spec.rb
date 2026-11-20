require 'spec_helper'

describe Arena do
  describe '.server' do
    it 'uses ARENA_ACCESS_TOKEN for v3 reads' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ARENA_ACCESS_TOKEN', nil).and_return('token')
      stub = stub_request(:get, 'https://api.are.na/v3/channels/x')
             .with(headers: { 'Authorization' => 'Bearer token', 'User-Agent' => 'slack-arena (+https://arena.playplay.io)' })
             .to_return(status: 200, body: '{"id":1}', headers: { 'Content-Type' => 'application/json' })
      expect(described_class.server.channel('x').id).to eq 1
      expect(stub).to have_been_requested
    end

    it 'is unauthenticated without ARENA_ACCESS_TOKEN' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ARENA_ACCESS_TOKEN', nil).and_return(nil)
      stub_request(:get, 'https://api.are.na/v3/channels/x')
        .to_return(status: 200, body: '{"id":1}', headers: { 'Content-Type' => 'application/json' })
      described_class.server.channel('x')
      expect(a_request(:get, 'https://api.are.na/v3/channels/x').with { |request| request.headers.key?('Authorization') }).not_to have_been_made
    end
  end

  describe 'v2 client' do
    it 'does not send a token' do
      stub_request(:get, %r{\Ahttps://api\.are\.na/v2/search/channels/})
        .to_return(status: 200, body: '{"channels":[]}', headers: { 'Content-Type' => 'application/json' })
      described_class.search('x', kind: 'channels')
      expect(a_request(:get, %r{/v2/search/channels/}).with { |request| request.headers.key?('Authorization') }).not_to have_been_made
    end
  end
end
