require 'spec_helper'

describe Arena::Added do
  subject do
    Arena::Added.new(story)
  end

  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }

  context 'added channel' do
    let(:filename) { 'spec/fixtures/arena/test-channel/2-added-channel-daniel-thomkins-cuban-web.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        image_url: nil,
        text: 'Connected to <https://www.are.na/daniel-tompkins/cuban-web|Cuban Web>.',
        title: 'Test Channel',
        title_link: 'https://www.are.na/daniel-doubrovkine/test-channel-1527426363'
      )
    end
  end

  context 'added url' do
    let(:filename) { 'spec/fixtures/arena/test-channel/3-added-url-all-about-art.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/2228365/original_79db9a938b9694ed19f4bd4fe1a9650e.png',
        text: 'Added to <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: 'All About Art',
        title_link: 'https://www.are.na/block/2228365'
      )
    end
  end

  context 'added jpg' do
    let(:filename) { 'spec/fixtures/arena/test-channel/4-added-jpg.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/2228366/original_dc77ce2c4562bbc8d66439262797ecd8.jpg',
        text: 'Added to <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: '2018-01-12-16.17.23.jpg',
        title_link: 'https://www.are.na/block/2228366'
      )
    end
  end

  context 'added text' do
    let(:filename) { 'spec/fixtures/arena/test-channel/6-added-text.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        image_url: nil,
        text: 'Added to <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: nil,
        title_link: 'https://www.are.na/block/2228371'
      )
    end
  end

  context 'added pdf' do
    let(:filename) { 'spec/fixtures/arena/test-channel/7-added-pdf.json' }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        image_url: nil,
        text: 'Added to <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: '43884722386-752316157-ticket.pdf',
        title_link: 'https://www.are.na/block/2228373'
      )
    end
  end

  context 'delightfully-absurd', vcr: { cassette_name: 'arena/channel_delightfully-absurd_feed' } do
    subject do
      Arena::Added.new(story)
    end

    let(:feed) { Arena.channel_feed(136_855, page: 1) }
    let(:story) { feed.stories.first }

    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_link: 'https://www.are.na/tess-french',
        author_name: 'Tess French',
        image_url: 'https://d2w9rnfcy7mm78.cloudfront.net/1965450/original_29641054c9190f7c5b7c09db486a6414',
        text: 'Added to <https://www.are.na/tess-french/delightfully-absurd|Delightfully absurd>.',
        title: nil,
        title_link: 'https://www.are.na/block/1965450'
      )
    end
  end
end
