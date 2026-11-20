require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures'
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  config.filter_sensitive_data('<ARENA_ACCESS_TOKEN>') { ENV.fetch('ARENA_ACCESS_TOKEN', nil) }
  config.before_record do |i|
    i.response.body.force_encoding('UTF-8')
  end
end
