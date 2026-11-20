Fabricator(:arena_user) do
  arena_id { Fabricate.sequence(:user_id) { |i| "4567#{i}" } }
  arena_slug { Faker::Internet.slug }
  arena_parent do
    {
      type: 'User',
      slug: Faker::Internet.slug,
      name: Faker::Name.name,
      bio: {
        plain: Faker::Lorem.sentence
      }
    }
  end
  channel_id '0HNTD0CW'
  channel_name 'fizbuzz'
end
