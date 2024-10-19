require 'spec_helper'

describe ArenaChannel do
  let(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user, team: team) }

  describe '#sync_new_arena_items!' do
    let(:channel) { Fabricate(:arena_channel, arena_id: 136_855, arena_slug: 'delightfully-absurd', team: team, created_by: user) }

    it 'updates arena_channel', vcr: { cassette_name: 'arena/channel_delightfully-absurd' } do
      expect(channel.title).to eq channel.title
      expect(channel).to receive(:stories_since_last_sync)
      expect(channel).to receive(:sync!)
      channel.sync_new_arena_items!
      expect(channel.title).to eq 'Delightfully absurd'
    end

    it 'updates sync_at' do
      expect(channel.sync_at).to be_nil
      expect(Arena).to receive(:try_channel).and_return(nil)
      expect(channel).to receive(:stories_since_last_sync) do
        expect(channel.sync_at).to be_nil
      end
      expect(channel).to receive(:sync!)
      channel.sync_new_arena_items!
      expect(channel.sync_at).not_to be_nil
    end

    it 'updates feed', vcr: { cassette_name: 'arena/channel_delightfully-absurd_feed' } do
      expect(Arena).to receive(:try_channel).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        attachments: [{
          author_name: 'Tess French',
          author_link: 'https://www.are.na/tess-french',
          text: 'Added to <https://www.are.na/tess-french/delightfully-absurd|Delightfully absurd>.',
          image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/1965450/original_29641054c9190f7c5b7c09db486a6414',
          title: nil,
          title_link: 'https://www.are.na/block/1965450'
        }],
        channel: '0HNTD0CW',
        as_user: true
      )
      channel.sync_new_arena_items!
      expect(channel.sync_at).not_to be_nil
    end

    it 'updates feed the second time', vcr: { cassette_name: 'arena/channel_delightfully-absurd_feed' } do
      channel.update_attributes!(sync_at: DateTime.new(2018, 3, 23))
      expect(Arena).to receive(:try_channel).and_return(nil)
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(6).times
      channel.sync_new_arena_items!
      expect(channel.sync_at).not_to be_nil
    end
  end
end
