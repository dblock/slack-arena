require 'spec_helper'

describe ArenaChannel do
  let(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user, team: team) }

  context 'title' do
    let(:arena_user) { Fabricate(:arena_user, arena_parent: arena_parent, team: team, created_by: user) }

    context 'with full name' do
      let(:arena_parent) { { full_name: 'Full Name' } }

      it 'uses full_name' do
        expect(arena_user.title).to eq 'Full Name'
      end
    end

    context 'with first and last' do
      let(:arena_parent) { { first_name: 'First', last_name: 'Last' } }

      it 'uses first and last' do
        expect(arena_user.title).to eq 'First Last'
      end
    end

    context 'with username' do
      let(:arena_parent) { { username: 'Username' } }

      it 'uses username' do
        expect(arena_user.title).to eq 'Username'
      end
    end

    context 'without any names' do
      let(:arena_parent) { {} }

      it 'defaults to anonymous' do
        expect(arena_user.title).to eq 'Anonymous'
      end
    end
  end

  describe '#sync_new_arena_items!' do
    let(:arena_user) { Fabricate(:arena_user, arena_id: 15, arena_slug: 'charles-broskoski', team: team, created_by: user) }

    it 'updates arena_user', vcr: { cassette_name: 'arena/user_charles-broskoski' } do
      expect(arena_user.title).to eq arena_user.title
      expect(arena_user).to receive(:stories_since_last_sync)
      expect(arena_user).to receive(:sync!)
      arena_user.sync_new_arena_items!
      expect(arena_user.title).to eq 'Charles Broskoski'
    end

    it 'updates sync_at' do
      expect(arena_user.sync_at).to be_nil
      expect(Arena).to receive(:try_user).and_return(nil)
      expect(arena_user).to receive(:stories_since_last_sync) do
        expect(arena_user.sync_at).to be_nil
      end
      expect(arena_user).to receive(:sync!)
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).not_to be_nil
    end

    it 'updates feed', vcr: { cassette_name: 'arena/user_charles-broskoski_feed' } do
      expect(Arena).to receive(:try_user).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        attachments: [{
          author_name: 'Charles Broskoski',
          author_link: 'https://www.are.na/charles-broskoski',
          text: 'Added to <https://www.are.na/charles-broskoski/home-office-2|Home Office 2>.',
          image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/2309330/original_038c9b1e187559a77c34dc5ede0bf7d2.jpg',
          title: 'Bryan Ferry &amp; Roxy Music - Lover (HD)',
          title_link: 'https://www.are.na/block/2309330'
        }],
        channel: '0HNTD0CW',
        as_user: true
      )
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).not_to be_nil
    end

    it 'updates feed the second time', vcr: { cassette_name: 'arena/user_charles-broskoski_feed' } do
      arena_user.update_attributes!(sync_at: DateTime.new(2018, 6, 11))
      expect(Arena).to receive(:try_user).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(20).times
      arena_user.sync_new_arena_items!
      expect(arena_user.sync_at).not_to be_nil
    end
  end
end
