require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  context 'users' do
    let(:user) { Fabricate(:user) }

    it 'connects a user to their Arena account', vcr: { cassette_name: 'arena/oauth_token' } do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postEphemeral).with(
        user: user.user_id,
        text: 'Successfully connected your Are.na account.',
        channel: 'C1'
      )

      client.user(id: user.id)._put(code: 'code', channel_id: 'C1')

      user.reload

      expect(user.arena_token).to eq 'token'
    end
  end
end
