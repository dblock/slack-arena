require 'spec_helper'

describe ArenaItem do
  let(:channel) do
    Fabricate.build(:arena_channel, arena_parent: { type: 'Channel', title: 'Ideas & Things', slug: 'ideas', owner: { slug: 'dblock' } })
  end
  let(:arena_user) { Fabricate.build(:arena_user, arena_parent: { type: 'User', slug: 'cab', name: 'Charles' }) }

  def item(attrs, feed)
    ArenaItem.new(Arena::V3::Resource.new(attrs.deep_stringify_keys), feed)
  end

  context 'in a channel feed' do
    it 'renders a block connected by another user' do
      expect(item({
                    id: 1,
                    type: 'Image',
                    title: 'A <b> & c',
                    created_at: '2020-01-01T00:00:00Z',
                    image: { src: 'https://example.com/1.jpg' },
                    user: { slug: 'owner', name: 'Owner' },
                    connection: { connected_at: '2026-01-01T00:00:00Z', connected_by: { slug: 'connector', username: 'connector' } }
                  }, channel).to_slack).to eq(
                    author_name: 'connector',
                    author_link: 'https://www.are.na/connector',
                    text: 'Added to <https://www.are.na/dblock/ideas|Ideas &amp; Things>.',
                    image_url: 'https://example.com/1.jpg',
                    title: 'A &lt;b&gt; &amp; c',
                    title_link: 'https://www.are.na/block/1'
                  )
    end

    it 'renders a connected channel' do
      expect(item({
                    id: 2,
                    type: 'Channel',
                    title: 'Other',
                    slug: 'other',
                    owner: { slug: 'group', name: 'Group' },
                    connection: { connected_at: '2026-01-01T00:00:00Z', connected_by: { slug: 'dblock', name: 'dB.' } }
                  }, channel).to_slack).to eq(
                    author_name: 'dB.',
                    author_link: 'https://www.are.na/dblock',
                    text: 'Connected to <https://www.are.na/dblock/ideas|Ideas &amp; Things>.',
                    image_url: nil,
                    title: 'Other',
                    title_link: 'https://www.are.na/group/other'
                  )
    end

    it 'uses the connection time' do
      expect(item({ created_at: '2020-01-01T00:00:00Z', connection: { connected_at: '2026-01-01T00:00:00Z' } }, channel).timestamp).to eq DateTime.new(2026, 1, 1)
    end
  end

  context 'in a user feed' do
    it 'renders a block' do
      expect(item({
                    id: 3,
                    type: 'Text',
                    title: nil,
                    created_at: '2026-01-01T00:00:00Z',
                    image: nil,
                    user: { slug: 'cab', name: 'Charles' }
                  }, arena_user).to_slack).to eq(
                    author_name: 'Charles',
                    author_link: 'https://www.are.na/cab',
                    text: 'Added a text block.',
                    image_url: nil,
                    title: nil,
                    title_link: 'https://www.are.na/block/3'
                  )
    end

    it 'renders an unknown block type' do
      expect(item({ id: 4, type: 'Hologram', user: { slug: 'cab', name: 'Charles' } }, arena_user).text).to eq 'Added a block.'
    end

    it 'renders a created channel' do
      expect(item({
                    id: 5,
                    type: 'Channel',
                    title: 'New',
                    slug: 'new',
                    created_at: '2026-01-01T00:00:00Z',
                    owner: { slug: 'cab', name: 'Charles' }
                  }, arena_user).to_slack).to eq(
                    author_name: 'Charles',
                    author_link: 'https://www.are.na/cab',
                    text: 'Created <https://www.are.na/cab/new|New>.',
                    image_url: nil,
                    title: 'New',
                    title_link: 'https://www.are.na/cab/new'
                  )
    end

    it 'uses the creation time' do
      expect(item({ created_at: '2026-01-02T03:04:05Z' }, arena_user).timestamp).to eq DateTime.new(2026, 1, 2, 3, 4, 5)
    end
  end
end
