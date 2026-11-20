require 'spec_helper'

describe ArenaChannel do
  let(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user, team: team) }

  context 'with a v3 parent' do
    let(:channel) do
      Fabricate(:arena_channel, team: team, created_by: user, arena_parent: {
                  type: 'Channel',
                  title: 'Ideas',
                  slug: 'ideas',
                  description: { markdown: '*Some* ideas.', plain: 'Some ideas.' },
                  owner: { type: 'Group', slug: 'a-group', avatar: 'https://example.com/avatar.png' }
                })
    end

    it 'renders' do
      expect(channel.title).to eq 'Ideas'
      expect(channel.arena_url).to eq 'https://www.are.na/a-group/ideas'
      expect(channel.thumb_url).to eq 'https://example.com/avatar.png'
      expect(channel.description).to eq 'Some ideas.'
    end
  end

  context 'with a v2 parent' do
    let(:channel) do
      Fabricate(:arena_channel, team: team, created_by: user, arena_parent: {
                  title: 'Ideas',
                  slug: 'ideas',
                  metadata: { description: 'Some ideas.' },
                  user: { slug: 'a-user', avatar: 'https://example.com/small.png', avatar_image: { display: 'https://example.com/avatar.png' } }
                })
    end

    it 'renders' do
      expect(channel.title).to eq 'Ideas'
      expect(channel.arena_url).to eq 'https://www.are.na/a-user/ideas'
      expect(channel.thumb_url).to eq 'https://example.com/avatar.png'
      expect(channel.description).to eq 'Some ideas.'
    end
  end

  context 'without a parent' do
    let(:channel) { Fabricate(:arena_channel, team: team, created_by: user, arena_parent: {}) }

    it 'renders' do
      expect(channel.title).to eq 'Untitled'
      expect(channel.thumb_url).to be_nil
      expect(channel.description).to be_nil
    end
  end

  describe '#sync_new_arena_items!' do
    let(:channel) do
      Fabricate(:arena_channel, arena_id: 136_855, arena_slug: 'delightfully-absurd', team: team, created_by: user, arena_parent: {
                  type: 'Channel',
                  title: 'Delightfully absurd',
                  slug: 'delightfully-absurd',
                  owner: { type: 'User', slug: 'tess-french' }
                })
    end

    context 'parent' do
      before do
        allow(channel).to receive(:items_since_last_sync).and_return([])
      end

      it 'replaces a v2 parent', vcr: { cassette_name: 'arena/v3/channel_delightfully-absurd' } do
        channel.update_attributes!(arena_parent: { title: 'Old', user: { slug: 'tess-french' } }, arena_parent_at: Time.now.utc)
        channel.sync_new_arena_items!
        expect(channel.arena_parent[:type]).to eq 'Channel'
        expect(channel.title).to eq 'Delightfully absurd'
        expect(channel.arena_url).to eq 'https://www.are.na/tess-french/delightfully-absurd'
        expect(channel.arena_parent_at).not_to be_nil
      end

      it 'refreshes a parent that was never refreshed', vcr: { cassette_name: 'arena/v3/channel_delightfully-absurd' } do
        expect(channel.arena_parent_at).to be_nil
        channel.sync_new_arena_items!
        expect(channel.arena_parent[:id]).to eq 136_855
        expect(channel.arena_parent_at).not_to be_nil
      end

      it 'refreshes a stale parent' do
        channel.update_attributes!(arena_parent_at: Time.now.utc - ArenaFeed::PARENT_TTL - 60)
        expect_any_instance_of(Arena::V3::Client).to receive(:try_channel).with(136_855).and_return(nil)
        channel.sync_new_arena_items!
        expect(channel.title).to eq 'Delightfully absurd'
      end

      it 'does not refresh a recent parent' do
        channel.update_attributes!(arena_parent_at: Time.now.utc)
        expect_any_instance_of(Arena::V3::Client).not_to receive(:try_channel)
        channel.sync_new_arena_items!
      end
    end

    context 'items' do
      before do
        allow_any_instance_of(Arena::V3::Client).to receive(:try_channel).and_return(nil)
      end

      it 'updates sync_at' do
        expect(channel.sync_at).to be_nil
        expect(channel).to receive(:items_since_last_sync) do
          expect(channel.sync_at).to be_nil
          []
        end
        channel.sync_new_arena_items!
        expect(channel.sync_at).not_to be_nil
      end

      it 'posts the newest item the first time', vcr: { cassette_name: 'arena/v3/channel_delightfully-absurd_contents' } do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          attachments: [{
            author_name: 'Tess French',
            author_link: 'https://www.are.na/tess-french',
            text: 'Added to <https://www.are.na/tess-french/delightfully-absurd|Delightfully absurd>.',
            image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/22889663/original_662ad37174aba6d9e67f18a348dc4fb0.jpg?1690792072',
            title: '1p6us?width=550',
            title_link: 'https://www.are.na/block/22889663'
          }],
          channel: '0HNTD0CW',
          as_user: true
        )
        channel.sync_new_arena_items!
        expect(channel.sync_at).not_to be_nil
      end

      it 'posts items connected since the last sync', vcr: { cassette_name: 'arena/v3/channel_delightfully-absurd_contents' } do
        channel.update_attributes!(sync_at: DateTime.new(2019, 1, 1))
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(6).times
        channel.sync_new_arena_items!
        expect(channel.sync_at).to be > DateTime.new(2019, 1, 1)
      end

      it 'pages and posts newest first' do
        channel.update_attributes!(sync_at: DateTime.new(2026, 1, 1))
        stub_arena_contents('channels/136855', 1, arena_contents([
                                                                   arena_block(1, '2026-03-01T00:00:00Z'),
                                                                   arena_block(2, '2026-04-01T00:00:00Z')
                                                                 ], has_more_pages: true))
        stub_arena_contents('channels/136855', 2, arena_contents([
                                                                   arena_block(3, '2025-01-01T00:00:00Z'),
                                                                   arena_block(4, '2026-02-01T00:00:00Z')
                                                                 ], has_more_pages: true))
        posted = []
        allow_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage) { |_, message| posted << message[:attachments][0][:title_link] }
        channel.sync_new_arena_items!
        expect(posted).to eq(%w[2 1 4].map { |id| "https://www.are.na/block/#{id}" })
        expect(a_request(:get, %r{/v3/channels/136855/contents.*page=3})).not_to have_been_made
      end

      it 'stops after MAX_PAGES' do
        channel.update_attributes!(sync_at: DateTime.new(2026, 1, 1))
        stub_request(:get, %r{/v3/channels/136855/contents}).to_return(
          status: 200,
          body: arena_contents([arena_block(1, '2026-03-01T00:00:00Z')], has_more_pages: true),
          headers: { 'Content-Type' => 'application/json' }
        )
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(ArenaFeed::MAX_PAGES).times
        channel.sync_new_arena_items!
      end

      it 'handles 403' do
        stub_request(:get, %r{/v3/channels/136855/contents}).to_return(
          status: 403,
          body: { error: 'Forbidden', code: 403, details: { message: 'You do not have access to this resource.' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        expect { channel.sync_new_arena_items! }.to raise_error Arena::V3::ForbiddenError do |e|
          expect(e.message).to eq '403: Forbidden - You do not have access to this resource.'
        end
        expect(channel.reload.sync_at).to be_nil
      end
    end
  end
end
