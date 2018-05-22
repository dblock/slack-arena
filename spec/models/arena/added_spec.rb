require 'spec_helper'

describe Arena::Added do
  context 'delightfully-absurd', vcr: { cassette_name: 'arena/channel_delightfully-absurd_feed' } do
    let(:feed) { Arena.channel_feed(136_855, page: 1) }
    let(:story) { feed.stories.first }
    subject do
      Arena::Added.new(story)
    end
    it 'slack block' do
      expect(subject.block).to eq(
        author_name: 'Connected to Delightfully absurd',
        author_link: 'https://www.are.na/tess-french/delightfully-absurd',
        color: nil,
        fields: nil,
        image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/1965450/original_29641054c9190f7c5b7c09db486a6414',
        text: nil,
        title: nil,
        title_link: 'http://mltshp.com/r/1DJRN/gifv'
      )
    end
  end
end
