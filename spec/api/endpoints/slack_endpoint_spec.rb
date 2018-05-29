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
    context 'interactive slack buttons' do
      it 'returns an error with a non-matching verification token' do
        post '/api/slack/action', payload: {
          actions: [{ name: 'arena_id', value: '1' }],
          channel: { id: 'C1', name: 'arena' },
          user: { id: 'user_id' },
          team: { id: 'team_id' },
          token: 'invalid-token',
          callback_id: 'disconnect-channel'
        }.to_json
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
    it 'fails slash commands' do
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
    it 'fails in interactive slack buttons' do
      post '/api/slack/action', payload: {
        actions: [{ name: 'arena_id', value: nil }],
        channel: { id: 'C1', name: 'arena' },
        user: { id: user.user_id },
        team: { id: team.team_id },
        token: '',
        callback_id: 'connect-channel'
      }.to_json
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
    context 'slash commands' do
      it 'fails an invalid command' do
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
      context 'connect' do
        it 'connects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
          expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
            attachments: [{
              title: 'Delightfully absurd',
              title_link: 'https://www.are.na/tess-french/delightfully-absurd',
              text: nil,
              thumb_url: 'https://gravatar.com/avatar/ff2006ef5406851c59bf46fcd2950055.png?s=150&d=mm&r=R&d=blank',
              color: '#000000',
              callback_id: 'disconnect-channel',
              actions: [{
                name: 'arena_id',
                text: 'Disconnect',
                type: 'button',
                value: 136_855
              }]
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
      context 'search' do
        it 'errors without a search term' do
          post '/api/slack/command',
               command: '/arena',
               text: 'search',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => 'Try searching for "something".',
            'user' => user.user_id
          )
        end
        it 'returns a list of channels', vcr: { cassette_name: 'arena/search_hockney' } do
          post '/api/slack/command',
               command: '/arena',
               text: 'search Hockney',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          json_response = JSON.parse(last_response.body)
          expect(json_response['channel']).to eq 'C1'
          expect(json_response['user']).to eq user.user_id
          expect(json_response['text']).to eq 'Searching for "Hockney" ...'
          expect(json_response['attachments'].size).to eq 5
          expect(json_response['attachments'][0]).to eq(
            'title' => 'The David Hockney Channel',
            'title_link' => 'https://www.are.na/charles-broskoski/the-david-hockney-channel',
            'text' => nil,
            'thumb_url' => 'https://s3.amazonaws.com/arena-avatars/15/medium_0169d93a7be2c5149947ae9c4dec8447.png?1493654235',
            'color' => '#000000',
            'callback_id' => 'connect-channel',
            'actions' => [
              {
                'name' => 'arena_id',
                'text' => 'Connect',
                'type' => 'button',
                'value' => 5910
              }
            ]
          )
        end
        context 'with a previously connected channel' do
          let!(:channel) { Fabricate(:channel, team: team, arena_id: '5910', channel_id: 'C1', created_by: user) }
          it 'turns a connect button into a disconnect', vcr: { cassette_name: 'arena/search_hockney' } do
            post '/api/slack/command',
                 command: '/arena',
                 text: 'search Hockney',
                 channel_id: 'C1',
                 channel_name: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: ''
            expect(last_response.status).to eq 201
            json_response = JSON.parse(last_response.body)
            expect(json_response['attachments'][0]['callback_id']).to eq 'disconnect-channel'
            expect(json_response['attachments'][0]['actions'][0]).to eq(
              'name' => 'arena_id',
              'text' => 'Disconnect',
              'type' => 'button',
              'value' => 5910
            )
          end
        end
      end
      context 'disconnect' do
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
        context 'with a connected channel' do
          let!(:channel) { Fabricate(:channel, channel_id: 'C1', team: team, created_by: user) }
          it 'disconnects a channel' do
            allow(Arena).to receive(:try_channel).and_return(nil)
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              attachments: [{
                title: channel.title,
                title_link: channel.arena_url,
                text: channel.description,
                thumb_url: channel.thumb_url,
                color: '#000000',
                callback_id: 'disconnect-channel',
                actions: [{
                  name: 'arena_id',
                  text: 'Disconnect',
                  type: 'button',
                  value: 12_340
                }]
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
          it 'does not double connect' do
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
    context 'interactive buttons' do
      it 'fails an invalid command' do
        allow(Arena).to receive(:try_channel).and_return(nil)
        post '/api/slack/action', payload: {
          actions: [{ name: 'arena_id', value: '1' }],
          channel: { id: 'C1', name: 'arena' },
          user: { id: user.user_id },
          team: { id: team.team_id },
          token: '',
          callback_id: 'whatever-callback'
        }.to_json
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq(
          'channel' => 'C1',
          'text' => "I don't understand \"whatever-callback\", sorry.",
          'user' => user.user_id
        )
      end
      it 'connects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          attachments: [{
            title: 'Delightfully absurd',
            title_link: 'https://www.are.na/tess-french/delightfully-absurd',
            text: nil,
            thumb_url: 'https://gravatar.com/avatar/ff2006ef5406851c59bf46fcd2950055.png?s=150&d=mm&r=R&d=blank',
            color: '#000000',
            callback_id: 'disconnect-channel',
            actions: [{
              name: 'arena_id',
              text: 'Disconnect',
              type: 'button',
              value: 136_855
            }]
          }],
          as_user: true,
          channel: 'C1',
          text: "A channel was connected by #{user.slack_mention}."
        )
        expect {
          post '/api/slack/action', payload: {
            actions: [{ name: 'arena_id', value: 'delightfully-absurd' }],
            channel: { id: 'C1', name: 'arena' },
            user: { id: user.user_id },
            team: { id: team.team_id },
            token: '',
            callback_id: 'connect-channel'
          }.to_json
          expect(last_response.status).to eq 201
          channel = team.channels.desc(:_id).first
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => '1 channel connected.',
            'attachments' => [{
              'title' => 'Delightfully absurd',
              'title_link' => 'https://www.are.na/tess-french/delightfully-absurd',
              'text' => nil,
              'thumb_url' => 'https://gravatar.com/avatar/ff2006ef5406851c59bf46fcd2950055.png?s=150&d=mm&r=R&d=blank',
              'color' => '#000000',
              'callback_id' => 'disconnect-channel',
              'actions' => [{
                'name' => 'arena_id',
                'text' => 'Disconnect',
                'type' => 'button',
                'value' => 136_855
              }]
            }],
            'user' => user.user_id
          )
          expect(channel.title).to eq 'Delightfully absurd'
        }.to change(Channel, :count).by(1)
      end
      it 'errors on an invalid channel', vcr: { cassette_name: 'arena/channel_invalid' } do
        expect {
          post '/api/slack/action', payload: {
            actions: [{ name: 'arena_id', value: 'invalid-channel' }],
            channel: { id: 'C1', name: 'arena' },
            user: { id: user.user_id },
            team: { id: team.team_id },
            token: '',
            callback_id: 'connect-channel'
          }.to_json
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => "I can't find the \"invalid-channel\" channel, sorry.",
            'user' => user.user_id
          )
        }.to_not change(Channel, :count)
      end
      context 'with a connected channel' do
        let!(:channel) { Fabricate(:channel, channel_id: 'C1', team: team, created_by: user, arena_id: 136_855) }
        it 'disconnects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
          expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
            attachments: [{
              title: channel.title,
              title_link: channel.arena_url,
              text: channel.description,
              thumb_url: channel.thumb_url,
              color: '#000000',
              callback_id: 'connect-channel',
              actions: [{
                name: 'arena_id',
                text: 'Connect',
                type: 'button',
                value: 136_855
              }]
            }],
            as_user: true,
            channel: 'C1',
            text: "A channel was disconnected by #{user.slack_mention}."
          )
          expect {
            post '/api/slack/action', payload: {
              actions: [{ name: 'arena_id', value: 136_855 }],
              channel: { id: 'C1', name: 'arena' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: '',
              callback_id: 'disconnect-channel'
            }.to_json
            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'channel' => 'C1',
              'text' => 'No channels connected. To connect a channel use `/arena search` or `/arena connect [channel]`.',
              'attachments' => [],
              'user' => user.user_id
            )
          }.to change(Channel, :count).by(-1)
        end
      end
    end
  end
end
