require 'spec_helper'

describe Api::Endpoints::SlackEndpoint do
  include Api::Test::EndpointTest

  context 'with a SLACK_VERIFICATION_TOKEN' do
    let(:token) { 'slack-verification-token' }
    before do
      ENV['SLACK_VERIFICATION_TOKEN'] = token
    end
    context 'slash commands' do
      it 'returns an error with a non-matching verification token' do
        post '/api/slack/command',
             command: '/arena',
             text: 'channels',
             channel_id: 'C1',
             channel_name: 'channel',
             user_id: 'user_id',
             team_id: 'team_id',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Slack.'
      end
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN')
    end
  end
  context 'not in channel' do
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team: team) }
    before do
      expect_any_instance_of(Team).to receive(:bot_in_channel?).and_return(false)
    end
    it 'fails to connect a channel' do
      post '/api/slack/command',
           command: '/arena',
           text: 'connect delightfully-absurd',
           channel_id: 'C1',
           channel_name: 'channel',
           user_id: user.user_id,
           team_id: team.team_id,
           token: ''
      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq(
        'channel' => 'C1',
        'text' => 'Please invite <@arena> to <#C1>, first.',
        'user' => user.user_id
      )
    end
  end
  context 'in channel' do
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team: team) }
    before do
      expect_any_instance_of(Team).to receive(:bot_in_channel?).and_return(true)
    end
    context 'invalid command' do
      it 'fails' do
        allow(Arena).to receive(:try_channel).and_return(nil)
        post '/api/slack/command',
             command: '/arena',
             text: 'whatever',
             channel_id: 'C1',
             channel_name: 'channel',
             user_id: user.user_id,
             team_id: team.team_id,
             token: ''
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq(
          'channel' => 'C1',
          'text' => "I don't understand \"whatever\", try \"<@arena> help\".",
          'user' => user.user_id
        )
      end
    end
    context 'not connected' do
      it 'connects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          attachments: [{
            title: 'Delightfully absurd',
            title_link: 'https://www.are.na/tess-french/delightfully-absurd',
            text: nil,
            thumb_url: 'https://gravatar.com/avatar/ff2006ef5406851c59bf46fcd2950055.png?s=150&d=mm&r=R&d=blank',
            color: '#000000'
          }],
          as_user: true,
          channel: 'C1',
          text: "A channel was connected by #{user.slack_mention}."
        )
        expect {
          post '/api/slack/command',
               command: '/arena',
               text: 'connect delightfully-absurd',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => 'Successfully connected "Delightfully absurd" to <#C1>.',
            'user' => user.user_id
          )
          channel = team.channels.desc(:_id).first
          expect(channel.title).to eq 'Delightfully absurd'
        }.to change(Channel, :count).by(1)
      end
      it 'errors when disconnecting a non-connected channel' do
        allow(Arena).to receive(:try_channel).and_return(nil)
        expect {
          post '/api/slack/command',
               command: '/arena',
               text: 'disconnect delightfully-absurd',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => "I haven't connected \"delightfully-absurd\" to <#C1>, sorry.",
            'user' => user.user_id
          )
        }.to_not change(Channel, :count)
      end
      it 'errors on an invalid channel', vcr: { cassette_name: 'arena/channel_invalid' } do
        expect {
          post '/api/slack/command',
               command: '/arena',
               text: 'connect invalid-channel',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => "I can't find the \"invalid-channel\" channel, sorry.",
            'user' => user.user_id
          )
        }.to_not change(Channel, :count)
      end
    end
    context 'subscribed channel' do
      let!(:channel) { Fabricate(:channel, channel_id: 'C1', team: team, created_by: user) }
      it 'unsubscribes a channel' do
        allow(Arena).to receive(:try_channel).and_return(nil)
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          attachments: [{
            title: channel.title,
            title_link: channel.arena_url,
            text: channel.description,
            thumb_url: channel.thumb_url,
            color: '#000000'
          }],
          as_user: true,
          channel: 'C1',
          text: "A channel was disconnected by #{user.slack_mention}."
        )
        expect {
          post '/api/slack/command',
               command: '/arena',
               text: "disconnect #{channel.arena_slug}",
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => "Successfully disconnected \"#{channel.title}\" from <#C1>.",
            'user' => user.user_id
          )
        }.to change(Channel, :count).by(-1)
      end
      it 'does not double subscribe' do
        allow(Arena).to receive(:try_channel).and_return(nil)
        expect {
          post '/api/slack/command',
               command: '/arena',
               text: "connect #{channel.arena_slug}",
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => "I have already connected \"#{channel.title}\" to <#C1>, sorry.",
            'user' => user.user_id
          )
        }.to_not change(Channel, :count)
      end
    end
  end
end
