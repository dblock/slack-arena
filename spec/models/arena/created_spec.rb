require 'spec_helper'

describe Arena::Created do
  subject do
    Arena::Created.new(story)
  end

  let(:filename) { 'spec/fixtures/arena/test-channel/1-created.json' }
  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }

  it '#to_slack' do
    expect(subject.to_slack).to eq(
      author_name: 'Daniel Doubrovkine',
      author_link: 'https://www.are.na/daniel-doubrovkine',
      text: 'Created <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
      title: 'Test Channel',
      title_link: 'https://www.are.na/daniel-doubrovkine/test-channel-1527426363'
    )
  end
end
