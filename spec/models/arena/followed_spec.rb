require 'spec_helper'

describe Arena::Followed do
  context 'delightfully-absurd', vcr: { cassette_name: 'arena/channel_record-covers-1499299389_feed' } do
    let(:feed) { Arena.channel_feed(79_336, page: 1) }
    let(:story) { feed.stories.first }
    subject do
      Arena::Followed.new(story)
    end
    it 'slack block' do
      expect(subject.block).to eq(
        author_name: 'Followed',
        color: nil,
        fields: [
          { title: 'Channels', value: 18, short: true },
          { title: 'Followers', value: 18, short: true }
        ],
        thumb_url: 'https://gravatar.com/avatar/2a4e485074730fcc48e0750368c4d579.png?s=150&d=mm&r=R&d=blank',
        title: 'Mikki Janower',
        title_link: 'https://www.are.na/rui-p/record-covers-1499299389'
      )
    end
  end
end
