Fabricator(:channel) do
  arena_id { Fabricate.sequence(:channel_id) { |i| "1234#{i}" } }
  title { Faker::Company.catch_phrase }
  channel_id '0HNTD0CW'
  channel_name 'fizbuzz'
end
