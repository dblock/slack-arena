require 'spec_helper'

describe Arena::Followed do
  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }
  subject do
    Arena::Followed.new(story)
  end
  context 'commented on a jpg' do
    let(:filename) { 'spec/fixtures/arena/test-channel/9-followed-channel.json' }
    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Block',
        author_link: 'https://www.are.na/daniel-block',
        text: '<https://www.are.na/daniel-block|Daniel Block> followed <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: 'Test Channel',
        title_link: 'https://www.are.na/daniel-doubrovkine/test-channel-1527426363'
      )
    end
  end
  context 'delightfully-absurd', vcr: { cassette_name: 'arena/channel_record-covers-1499299389_feed' } do
    let(:feed) { Arena.channel_feed(79_336, page: 1) }
    let(:story) { feed.stories.first }
    it 'slack block' do
      expect(subject.to_slack).to eq(
        author_name: 'Mikki Janower',
        author_link: 'https://www.are.na/mikki-janower',
        text: '<https://www.are.na/mikki-janower|Mikki Janower> followed <https://www.are.na/rui-p/record-covers-1499299389|Record Covers >.',
        title: 'Record Covers ',
        title_link: 'https://www.are.na/rui-p/record-covers-1499299389'
      )
    end
  end
end
