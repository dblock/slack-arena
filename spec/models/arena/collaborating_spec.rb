require 'spec_helper'

describe Arena::Collaborating do
  let(:file) { File.read(filename) }
  let(:json) { JSON.parse(file) }
  let(:story) { Arena::Story.new(json) }
  subject do
    Arena::Collaborating.new(story)
  end
  context 'added collaborator' do
    let(:filename) { 'spec/fixtures/arena/test-channel/8-is-collaborating-with-added-collaborator.json' }
    it '#to_slack' do
      expect(subject.to_slack).to eq(
        author_name: 'Daniel Doubrovkine',
        author_link: 'https://www.are.na/daniel-doubrovkine',
        text: '<https://www.are.na/daniel-doubrovkine|Daniel Doubrovkine> added <https://www.are.na/charles-broskoski|Charles Broskoski> as collaborator to <https://www.are.na/daniel-doubrovkine/test-channel-1527426363|Test Channel>.',
        title: 'Test Channel',
        title_link: 'https://www.are.na/daniel-doubrovkine/test-channel-1527426363'
      )
    end
  end
end
