Fabricator(:arena_channel) do
  arena_id { Fabricate.sequence(:channel_id) { |i| "1234#{i}" } }
  arena_slug { Faker::Internet.slug }
  arena_parent do
    {
      title: Faker::Company.catch_phrase,
      metadata: {
        description: Faker::Lorem.sentence
      },
      user: {
        slug: Faker::Internet.slug
      }
    }
  end
  channel_id '0HNTD0CW'
  channel_name 'fizbuzz'
end
