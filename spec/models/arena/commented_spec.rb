require 'spec_helper'

describe Arena::Commented do
  subject do
    Arena::Commented.new(story)
  end

  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }

  context 'commented on a jpg' do
    let(:filename) { 'spec/fixtures/arena/test-channel/5-commented-on-jpg-block.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        text: 'This is a random photo.',
        title: '2018-01-12-16.17.23.jpg',
        title_link: 'https://www.are.na/block/2228366'
      )
    end
  end
end
