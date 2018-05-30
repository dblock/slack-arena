Fabricator(:arena_user) do
  arena_id { Fabricate.sequence(:user_id) { |i| "4567#{i}" } }
  arena_slug { Faker::Internet.slug(nil, '-') }
  arena_parent do
    {
      slug: Faker::Internet.slug(nil, '-'),
      full_name: Faker::Name.name,
      metadata: {
        description: Faker::Lorem.sentence
      }
    }
  end
  channel_id '0HNTD0CW'
  channel_name 'fizbuzz'
end
