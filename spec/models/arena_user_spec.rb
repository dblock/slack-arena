require 'spec_helper'

describe ArenaUser do
  let(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user, team: team) }

  context 'title' do
    let(:arena_user) { Fabricate(:arena_user, arena_parent: arena_parent, team: team, created_by: user) }

    context 'with name' do
      let(:arena_parent) { { type: 'User', name: 'Name', full_name: 'Full Name' } }

      it 'uses name' do
        expect(arena_user.title).to eq 'Name'
      end
    end

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

  context 'with a v3 parent' do
    let(:arena_user) do
      Fabricate(:arena_user, team: team, created_by: user, arena_parent: {
                  type: 'User', slug: 'cab', name: 'Charles Broskoski', avatar: 'https://example.com/avatar.jpg', bio: { plain: 'Co-founder.' }
                })
    end

    it 'renders' do
      expect(arena_user.arena_url).to eq 'https://www.are.na/cab'
      expect(arena_user.thumb_url).to eq 'https://example.com/avatar.jpg'
      expect(arena_user.description).to eq 'Co-founder.'
    end
  end

  context 'with a v2 parent' do
    let(:arena_user) do
      Fabricate(:arena_user, team: team, created_by: user, arena_parent: {
                  slug: 'charles-broskoski', full_name: 'Charles Broskoski', avatar_image: { display: 'https://example.com/avatar.jpg' }, metadata: { description: 'Co-founder.' }
                })
    end

    it 'renders' do
      expect(arena_user.arena_url).to eq 'https://www.are.na/charles-broskoski'
      expect(arena_user.thumb_url).to eq 'https://example.com/avatar.jpg'
      expect(arena_user.description).to eq 'Co-founder.'
    end
  end

  describe '#sync_new_arena_items!' do
    let(:arena_user) do
      Fabricate(:arena_user, arena_id: 15, arena_slug: 'cab', team: team, created_by: user, arena_parent: {
                  type: 'User', slug: 'cab', name: 'Charles Broskoski'
                })
    end

    it 'replaces a v2 parent', vcr: { cassette_name: 'arena/v3/user_cab' } do
      arena_user.update_attributes!(arena_parent: { slug: 'charles-broskoski', full_name: 'Charles' }, arena_parent_at: Time.now.utc)
      expect(arena_user).to receive(:items_since_last_sync).and_return([])
      arena_user.sync_new_arena_items!
      expect(arena_user.title).to eq 'Charles Broskoski'
      expect(arena_user.arena_url).to eq 'https://www.are.na/cab'
    end

    context 'items' do
      before do
        allow_any_instance_of(Arena::V3::Client).to receive(:try_user).and_return(nil)
      end

      it 'updates sync_at' do
        expect(arena_user.sync_at).to be_nil
        expect(arena_user).to receive(:items_since_last_sync) do
          expect(arena_user.sync_at).to be_nil
          []
        end
        arena_user.sync_new_arena_items!
        expect(arena_user.sync_at).not_to be_nil
      end

      it 'posts the newest item the first time', vcr: { cassette_name: 'arena/v3/user_cab_contents' } do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          attachments: [{
            author_name: 'Charles Broskoski',
            author_link: 'https://www.are.na/cab',
            text: 'Added a link.',
            image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/53047310/original_67320336574f453636df6f5ebadfc39c.png?1795199914',
            title: 'Are.na RSVP',
            title_link: 'https://www.are.na/block/53047310'
          }],
          channel: '0HNTD0CW',
          as_user: true
        )
        arena_user.sync_new_arena_items!
      end

      it 'posts items created since the last sync', vcr: { cassette_name: 'arena/v3/user_cab_contents' } do
        arena_user.update_attributes!(sync_at: DateTime.new(2026, 11, 16))
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(20).times
        arena_user.sync_new_arena_items!
      end
    end
  end
end
