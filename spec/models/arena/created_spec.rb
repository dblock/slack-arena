require 'spec_helper'

describe Arena::Created do
  let(:filename) { 'spec/fixtures/arena/test-channel/1-created.json' }
  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }
  subject do
    Arena::Created.new(story)
  end
  it '#to_slack' do
    expect(subject.to_slack).to eq(
      author_name: 'Daniel Doubrovkine',
      author_link: 'https://www.are.na/daniel-doubrovkine',
      title: 'Test Channel',
      title_link: 'https://www.are.na/daniel-doubrovkine/test-channel-1527426363'
    )
  end
end
