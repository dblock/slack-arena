require 'spec_helper'

describe ArenaChannel do
  let(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user, team: team) }
  context '#sync_new_arena_items!' do
    let(:arena_user) { Fabricate(:arena_user, arena_id: 15, arena_slug: 'charles-broskoski', team: team, created_by: user) }
    it 'updates arena_user', vcr: { cassette_name: 'arena/user_charles-broskoski' } do
      expect(arena_user.title).to eq arena_user.title
      expect(arena_user).to receive(:stories_since_last_sync)
      expect(arena_user).to receive(:sync!)
      arena_user.sync_new_arena_items!
      expect(arena_user.title).to eq 'Charles Broskoski'
    end
    it 'updates sync_at' do
      expect(arena_user.sync_at).to be nil
      expect(Arena).to receive(:try_user).and_return(nil)
      expect(arena_user).to receive(:stories_since_last_sync) do
        expect(arena_user.sync_at).to be nil
      end
      expect(arena_user).to receive(:sync!)
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).to_not be nil
    end
    it 'updates feed', vcr: { cassette_name: 'arena/user_charles-broskoski_feed' } do
      expect(Arena).to receive(:try_user).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        attachments: [{
          author_name: 'Charles Broskoski',
          author_link: 'https://www.are.na/charles-broskoski',
          text: '<https://www.are.na/charles-broskoski|Charles Broskoski> followed <https://www.are.na/luming-hao/please-join-my-webring|please join my webring 🌐>.',
          title: 'please join my webring 🌐',
          title_link: 'https://www.are.na/luming-hao/please-join-my-webring'
        }],
        channel: '0HNTD0CW',
        as_user: true
      )
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).to_not be nil
    end
    it 'updates feed the second time', vcr: { cassette_name: 'arena/user_charles-broskoski_feed' } do
      arena_user.update_attributes(sync_at: Date.new(2018, 4, 28))
      expect(Arena).to receive(:try_user).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(20).times
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).to_not be nil
    end
  end
end
