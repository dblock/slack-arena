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
      it 'invokes action with a verification token' do
        post '/api/slack/action', token: token
        expect(last_response.status).to eq 400
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq 'Invalid parameters.'
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
          callback_id: 'disconnect'
        }.to_json
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Slack.'
      end
      it 'invokes action with a verification token' do
        post '/api/slack/action', payload: {
          token: token
        }.to_json
        expect(last_response.status).to eq 400
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq 'Invalid parameters.'
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
        callback_id: 'connect'
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
      allow_any_instance_of(Team).to receive(:bot_in_channel?).and_return(true)
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
      context 'feeds' do
        it 'returns no feeds' do
          post '/api/slack/command',
               command: '/arena',
               text: 'feeds',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => 'No feeds. To connect a channel or to follow a user use `/arena search` or `/arena connect|follow [channel|user]`.',
            'user' => user.user_id
          )
        end
        context 'with previously connected channels and users' do
          let!(:arena_channel) { Fabricate(:arena_channel, team: team, arena_id: '5910', channel_id: 'C1', created_by: user) }
          let!(:arena_user) { Fabricate(:arena_user, team: team, arena_id: '1234', channel_id: 'C1', created_by: user) }
          it 'returns both channels and users' do
            post '/api/slack/command',
                 command: '/arena',
                 text: 'feeds',
                 channel_id: 'C1',
                 channel_name: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: ''
            expect(last_response.status).to eq 201
            json_response = JSON.parse(last_response.body)
            expect(json_response['text']).to eq '2 feeds.'
            expect(json_response['attachments'].size).to eq 2
          end
        end
      end
      context 'channels' do
        it 'returns no feeds' do
          post '/api/slack/command',
               command: '/arena',
               text: 'channels',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => 'No channels. To connect a channel or to follow a user use `/arena search` or `/arena connect|follow [channel|user]`.',
            'user' => user.user_id
          )
        end
        context 'with previously connected channels and users' do
          let!(:arena_channel) { Fabricate(:arena_channel, team: team, arena_id: '5910', channel_id: 'C1', created_by: user) }
          let!(:arena_user) { Fabricate(:arena_user, team: team, arena_id: '1234', channel_id: 'C1', created_by: user) }
          it 'returns only channels' do
            post '/api/slack/command',
                 command: '/arena',
                 text: 'channels',
                 channel_id: 'C1',
                 channel_name: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: ''
            expect(last_response.status).to eq 201
            json_response = JSON.parse(last_response.body)
            expect(json_response['text']).to eq '1 channel.'
            expect(json_response['attachments'][0].deep_symbolize_keys).to eq arena_channel.connect_to_slack_attachment
          end
        end
      end
      context 'users' do
        it 'returns no feeds' do
          post '/api/slack/command',
               command: '/arena',
               text: 'users',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            'channel' => 'C1',
            'text' => 'No users. To connect a channel or to follow a user use `/arena search` or `/arena connect|follow [channel|user]`.',
            'user' => user.user_id
          )
        end
        context 'with previously connected channels and users' do
          let!(:arena_channel) { Fabricate(:arena_channel, team: team, arena_id: '5910', channel_id: 'C1', created_by: user) }
          let!(:arena_user) { Fabricate(:arena_user, team: team, arena_id: '1234', channel_id: 'C1', created_by: user) }
          it 'returns only users' do
            post '/api/slack/command',
                 command: '/arena',
                 text: 'users',
                 channel_id: 'C1',
                 channel_name: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: ''
            expect(last_response.status).to eq 201
            json_response = JSON.parse(last_response.body)
            expect(json_response['text']).to eq '1 user.'
            expect(json_response['attachments'][0].deep_symbolize_keys).to eq arena_user.connect_to_slack_attachment
          end
        end
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
              callback_id: 'disconnect',
              actions: [{
                name: 'arena_id',
                text: 'Disconnect',
                type: 'button',
                value: 136_855
              }]
            }],
            as_user: true,
            channel: 'C1',
            text: "Subscribed by #{user.slack_mention}."
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
              'text' => 'Now posting "Delightfully absurd" updates to <#C1>.',
              'user' => user.user_id
            )
            channel = team.arena_feeds.desc(:_id).first
            expect(channel.title).to eq 'Delightfully absurd'
          }.to change(ArenaChannel, :count).by(1)
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
              'text' => "I can't find \"invalid-channel\", sorry.",
              'user' => user.user_id
            )
          }.to_not change(ArenaChannel, :count)
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
        it 'returns a list of channels and users', vcr: { cassette_name: 'arena/search_david' } do
          post '/api/slack/command',
               command: '/arena',
               text: 'search David',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: ''
          expect(last_response.status).to eq 201
          json_response = JSON.parse(last_response.body)
          expect(json_response['channel']).to eq 'C1'
          expect(json_response['user']).to eq user.user_id
          expect(json_response['text']).to eq 'Searching for "David" ...'
          expect(json_response['attachments'].size).to eq 6
          expect(json_response['attachments'][0]).to eq(
            'title' => 'David Hilmer Rex',
            'title_link' => 'https://www.are.na/david-hilmer-rex',
            'text' => nil,
            'thumb_url' => 'https://s3.amazonaws.com/arena-avatars/289/medium_42050d9ad63943472112b08d2fa3688b.png?1434488932',
            'color' => '#000000',
            'callback_id' => 'follow',
            'actions' => [
              {
                'name' => 'arena_id',
                'text' => 'Follow',
                'type' => 'button',
                'value' => 289
              }
            ]
          )
          expect(json_response['attachments'][1]).to eq(
            'title' => 'David Shrigley',
            'title_link' => 'https://www.are.na/thomas-bouillot/david-shrigley',
            'text' => nil,
            'thumb_url' => 'https://gravatar.com/avatar/38a39240fbfcc4cd760f8a3eb1c64b7f.png?s=150&d=mm&r=R&d=blank',
            'color' => '#000000',
            'callback_id' => 'connect',
            'actions' => [
              {
                'name' => 'arena_id',
                'text' => 'Connect',
                'type' => 'button',
                'value' => 198_637
              }
            ]
          )
        end
        context 'with a previously connected channel and user' do
          let!(:arena_user) { Fabricate(:arena_user, arena_parent: { full_name: 'David Hilmer Rex' }, team: team, arena_id: 289, channel_id: 'C1', created_by: user) }
          let!(:arena_channel) { Fabricate(:arena_channel, arena_parent: { title: 'David Shrigley' }, team: team, arena_id: 198_637, channel_id: 'C1', created_by: user) }
          it 'inverts button actions', vcr: { cassette_name: 'arena/search_david' } do
            post '/api/slack/command',
                 command: '/arena',
                 text: 'search David',
                 channel_id: 'C1',
                 channel_name: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: ''
            expect(last_response.status).to eq 201
            json_response = JSON.parse(last_response.body)
            attachments_user = json_response['attachments'][0]
            expect(attachments_user['callback_id']).to eq 'unfollow'
            expect(attachments_user['actions'][0]).to eq(
              'name' => 'arena_id',
              'text' => 'Unfollow',
              'type' => 'button',
              'value' => arena_user.arena_id
            )
            attachments_channel = json_response['attachments'][1]
            expect(attachments_channel['callback_id']).to eq 'disconnect'
            expect(attachments_channel['actions'][0]).to eq(
              'name' => 'arena_id',
              'text' => 'Disconnect',
              'type' => 'button',
              'value' => arena_channel.arena_id
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
              'text' => "I don't know anything about \"delightfully-absurd\" in <#C1>, sorry.",
              'user' => user.user_id
            )
          }.to_not change(ArenaChannel, :count)
        end
        context 'with a connected channel' do
          let!(:channel) { Fabricate(:arena_channel, channel_id: 'C1', team: team, created_by: user) }
          it 'disconnects a channel' do
            allow(Arena).to receive(:try_channel).and_return(nil)
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              attachments: [{
                title: channel.title,
                title_link: channel.arena_url,
                text: channel.description,
                thumb_url: channel.thumb_url,
                color: '#000000',
                callback_id: 'connect',
                actions: [{
                  name: 'arena_id',
                  text: 'Connect',
                  type: 'button',
                  value: 12_340
                }]
              }],
              as_user: true,
              channel: 'C1',
              text: "Unsubscribed by #{user.slack_mention}."
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
                'text' => "No longer posting \"#{channel.title}\" updates to <#C1>.",
                'user' => user.user_id
              )
            }.to change(ArenaChannel, :count).by(-1)
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
                'text' => "I'm already posting \"#{channel.title}\" updates to <#C1>.",
                'user' => user.user_id
              )
            }.to_not change(ArenaChannel, :count)
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
          'text' => "I don't understand \"whatever-callback 1\", try \"<@arena> help\".",
          'user' => user.user_id
        )
      end
      it 'posts errors to response_url when available' do
        expect(HTTParty).to receive(:post).with(
          'https://example.com/response_url',
          body: { text: "I don't understand \"whatever-callback 1\", try \"<@arena> help\".", type: 'ephemeral' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        allow(Arena).to receive(:try_channel).and_return(nil)
        post '/api/slack/action', payload: {
          actions: [{ name: 'arena_id', value: '1' }],
          channel: { id: 'C1', name: 'arena' },
          user: { id: user.user_id },
          team: { id: team.team_id },
          token: '',
          callback_id: 'whatever-callback',
          response_url: 'https://example.com/response_url'
        }.to_json
        expect(last_response.status).to eq 201
      end
      context 'channels' do
        it 'connects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
          expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
            attachments: [{
              title: 'Delightfully absurd',
              title_link: 'https://www.are.na/tess-french/delightfully-absurd',
              text: nil,
              thumb_url: 'https://gravatar.com/avatar/ff2006ef5406851c59bf46fcd2950055.png?s=150&d=mm&r=R&d=blank',
              color: '#000000',
              callback_id: 'disconnect',
              actions: [{
                name: 'arena_id',
                text: 'Disconnect',
                type: 'button',
                value: 136_855
              }]
            }],
            as_user: true,
            channel: 'C1',
            text: "Subscribed by #{user.slack_mention}."
          )
          expect {
            post '/api/slack/action', payload: {
              actions: [{ name: 'arena_id', value: 'delightfully-absurd' }],
              channel: { id: 'C1', name: 'arena' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: '',
              callback_id: 'connect'
            }.to_json
            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'channel' => 'C1',
              'text' => 'Now posting "Delightfully absurd" updates to <#C1>.',
              'user' => user.user_id
            )
            arena_channel = team.arena_channel_feeds.desc(:_id).first
            expect(arena_channel.title).to eq 'Delightfully absurd'
          }.to change(ArenaChannel, :count).by(1)
        end
        it 'errors on an invalid channel', vcr: { cassette_name: 'arena/channel_invalid' } do
          expect {
            post '/api/slack/action', payload: {
              actions: [{ name: 'arena_id', value: 'invalid-channel' }],
              channel: { id: 'C1', name: 'arena' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: '',
              callback_id: 'connect'
            }.to_json
            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'channel' => 'C1',
              'text' => "I can't find \"invalid-channel\", sorry.",
              'user' => user.user_id
            )
          }.to_not change(ArenaChannel, :count)
        end
        context 'with a connected channel' do
          let!(:arena_channel) { Fabricate(:arena_channel, channel_id: 'C1', team: team, created_by: user, arena_id: 136_855) }
          it 'disconnects to a channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              attachments: [{
                title: arena_channel.title,
                title_link: arena_channel.arena_url,
                text: arena_channel.description,
                thumb_url: arena_channel.thumb_url,
                color: '#000000',
                callback_id: 'connect',
                actions: [{
                  name: 'arena_id',
                  text: 'Connect',
                  type: 'button',
                  value: 136_855
                }]
              }],
              as_user: true,
              channel: 'C1',
              text: "Unsubscribed by #{user.slack_mention}."
            )
            expect {
              post '/api/slack/action', payload: {
                actions: [{ name: 'arena_id', value: arena_channel.arena_id }],
                channel: { id: 'C1', name: 'arena' },
                user: { id: user.user_id },
                team: { id: team.team_id },
                token: '',
                callback_id: 'disconnect'
              }.to_json
              expect(last_response.status).to eq 201
              expect(JSON.parse(last_response.body)).to eq(
                'channel' => 'C1',
                'text' => "No longer posting \"#{arena_channel.title}\" updates to <#C1>.",
                'user' => user.user_id
              )
            }.to change(ArenaChannel, :count).by(-1)
          end
        end
      end
      context 'users' do
        it 'follows to a user', vcr: { cassette_name: 'arena/user_charles-broskoski' } do
          expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
            attachments: [{
              title: 'Charles Broskoski',
              title_link: 'https://www.are.na/charles-broskoski',
              text: "[Are.na](http://are.na) co-founder ✍︎\n\nhttp://charlesbroskoski.com\n",
              thumb_url: 'https://s3.amazonaws.com/arena-avatars/15/medium_0169d93a7be2c5149947ae9c4dec8447.png?1493654235',
              color: '#000000',
              callback_id: 'unfollow',
              actions: [{
                name: 'arena_id',
                text: 'Unfollow',
                type: 'button',
                value: 15
              }]
            }],
            as_user: true,
            channel: 'C1',
            text: "Subscribed by #{user.slack_mention}."
          )
          expect {
            post '/api/slack/action', payload: {
              actions: [{ name: 'arena_id', value: 'charles-broskoski' }],
              channel: { id: 'C1', name: 'arena' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: '',
              callback_id: 'follow'
            }.to_json
            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'channel' => 'C1',
              'text' => 'Now posting "Charles Broskoski" updates to <#C1>.',
              'user' => user.user_id
            )
            arena_user = team.arena_user_feeds.desc(:_id).first
            expect(arena_user.title).to eq 'Charles Broskoski'
          }.to change(ArenaUser, :count).by(1)
        end
        it 'errors on an invalid user', vcr: { cassette_name: 'arena/user_invalid' } do
          expect {
            post '/api/slack/action', payload: {
              actions: [{ name: 'arena_id', value: 'invalid-user' }],
              channel: { id: 'C1', name: 'arena' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: '',
              callback_id: 'follow'
            }.to_json
            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'channel' => 'C1',
              'text' => "I can't find \"invalid-user\", sorry.",
              'user' => user.user_id
            )
          }.to_not change(ArenaUser, :count)
        end
        context 'with a followed user' do
          let!(:arena_user) { Fabricate(:arena_user, channel_id: 'C1', team: team, created_by: user, arena_id: 15) }
          it 'unfollows a user', vcr: { cassette_name: 'arena/user_charles-broskoski' } do
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              attachments: [{
                title: arena_user.title,
                title_link: arena_user.arena_url,
                text: arena_user.description,
                thumb_url: arena_user.thumb_url,
                color: '#000000',
                callback_id: 'follow',
                actions: [{
                  name: 'arena_id',
                  text: 'Follow',
                  type: 'button',
                  value: arena_user.arena_id
                }]
              }],
              as_user: true,
              channel: 'C1',
              text: "Unsubscribed by #{user.slack_mention}."
            )
            expect {
              post '/api/slack/action', payload: {
                actions: [{ name: 'arena_id', value: arena_user.arena_id }],
                channel: { id: 'C1', name: 'arena' },
                user: { id: user.user_id },
                team: { id: team.team_id },
                token: '',
                callback_id: 'unfollow'
              }.to_json
              expect(last_response.status).to eq 201
              expect(JSON.parse(last_response.body)).to eq(
                'channel' => 'C1',
                'text' => "No longer posting \"#{arena_user.title}\" updates to <#C1>.",
                'user' => user.user_id
              )
            }.to change(ArenaUser, :count).by(-1)
          end
        end
        context 'add' do
          context 'when user is connected to arena' do
            before do
              user.update_attributes!(arena_token: 'token')
            end
            it 'returns an error on invalid action' do
              post '/api/slack/action', payload: {
                channel: { id: 'C1', name: 'arena' },
                user: { id: user.user_id },
                team: { id: team.team_id },
                token: '',
                type: 'invalid',
                callback_id: 'add'
              }.to_json
              expect(last_response.status).to eq 400
              json_response = JSON.parse(last_response.body)
              expect(json_response['message']).to eq 'Unsupported action type: invalid.'
            end
            context 'message_action' do
              it 'opens a dialog with text and channel selection', vcr: { cassette_name: 'arena/account_channels' } do
                expect_any_instance_of(Slack::Web::Client).to receive(:dialog_open).with(
                  dialog: {
                    callback_id: 'add',
                    title: 'Post to Are.na',
                    submit_label: 'Post',
                    elements: [
                      {
                        type: 'textarea',
                        label: 'Text',
                        name: 'text',
                        value: nil
                      },
                      {
                        type: 'select',
                        label: 'Channel',
                        name: 'channel',
                        options: [
                          { label: 'Test Channel', value: 198_378 },
                          { label: 'Another Test Channel ', value: 198_382 },
                          { label: 'Photographing People in the Streets of Havana, Cuba', value: 119_592 },
                          { label: 'CTO', value: 119_599 },
                          { label: 'Photographing People in the Streets of New York, NY', value: 119_597 }
                        ]
                      }
                    ]
                  },
                  trigger_id: 'T1'
                )
                post '/api/slack/action', payload: {
                  channel: { id: 'C1', name: 'arena' },
                  user: { id: user.user_id },
                  team: { id: team.team_id },
                  token: '',
                  type: 'message_action',
                  trigger_id: 'T1',
                  callback_id: 'add'
                }.to_json
                expect(last_response.status).to eq 204
              end
            end
            context 'dialog_submission' do
              context 'creates arena blocks in test channel' do
                before do
                  expect_any_instance_of(Slack::Web::Client).to receive(:chat_postEphemeral).with(
                    text: 'Added to Are.na in <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
                    user: user.user_id,
                    channel: 'C1'
                  )
                end
                it 'creates an arena block of text', vcr: { cassette_name: 'arena/channel_198_378' } do
                  expect_any_instance_of(Arena::Client).to receive(:channel_add_block).with(198_378, content: 'text')
                  post '/api/slack/action', payload: {
                    channel: { id: 'C1', name: 'arena' },
                    user: { id: user.user_id },
                    team: { id: team.team_id },
                    token: '',
                    type: 'dialog_submission',
                    trigger_id: 'T1',
                    callback_id: 'add',
                    submission: {
                      text: 'text',
                      channel: 198_378
                    }
                  }.to_json
                  expect(last_response.status).to eq 204
                end
                it 'creates an arena block with source', vcr: { cassette_name: 'arena/channel_198_378' } do
                  expect_any_instance_of(Arena::Client).to receive(:channel_add_block).with(198_378, source: 'https://example.com')
                  post '/api/slack/action', payload: {
                    channel: { id: 'C1', name: 'arena' },
                    user: { id: user.user_id },
                    team: { id: team.team_id },
                    token: '',
                    type: 'dialog_submission',
                    trigger_id: 'T1',
                    callback_id: 'add',
                    submission: {
                      text: 'https://example.com',
                      channel: 198_378
                    }
                  }.to_json
                  expect(last_response.status).to eq 204
                end
              end
            end
          end
          context 'when user is not connected to arena' do
            it 'asks the user to connect the arena account' do
              state = { user_id: user.id.to_s, channel_id: 'C1' }
              connect_url = "https://dev.are.na/oauth/authorize?client_id=&redirect_uri=https://arena.playplay.io/connect&response_type=code&state=#{state.to_json}"
              expect_any_instance_of(Slack::Web::Client).to receive(:chat_postEphemeral).with(
                text: 'Please connect your Are.na account.',
                attachments: [{
                  fallback: "Please connect your Are.na account at #{connect_url}.",
                  actions: [{
                    type: 'button',
                    text: 'Click Here',
                    url: connect_url
                  }]
                }],
                user: user.user_id,
                channel: 'C1'
              )
              post '/api/slack/action', payload: {
                channel: { id: 'C1', name: 'arena' },
                user: { id: user.user_id },
                team: { id: team.team_id },
                token: '',
                callback_id: 'add'
              }.to_json
              expect(last_response.status).to eq 204
            end
          end
        end
      end
    end
  end
end
