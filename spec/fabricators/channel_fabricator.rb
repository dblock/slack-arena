Fabricator(:channel) do
  arena_id { Fabricate.sequence(:channel_id) { |i| "1234#{i}" } }
  arena_slug { Faker::Internet.slug(nil, '-') }
  title { Faker::Company.catch_phrase }
  channel_id '0HNTD0CW'
  channel_name 'fizbuzz'
end
