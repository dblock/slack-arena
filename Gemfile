source 'http://rubygems.org'

ruby '2.5.0'

gem 'arena', github: 'dblock/arena-rb', branch: 'user-feed'
gem 'grape'
gem 'grape_logging'
gem 'hashie'
gem 'mongoid'
gem 'mongoid-scroll'
gem 'newrelic_rpm'
gem 'nokogiri'
gem 'rack-robotz'
gem 'rack-server-pages'
gem 'slack-ruby-bot-server'
gem 'slack-ruby-client'
gem 'stripe', '~> 1.58.0'
gem 'wannabe_bool'

group :development, :test do
  gem 'foreman'
  gem 'rake', '~> 10.4'
  gem 'rubocop', '0.56.0'
end

group :development do
  gem 'mongoid-shell'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'faker'
  gem 'hyperclient'
  gem 'rack-test'
  gem 'rspec'
  gem 'selenium-webdriver'
  gem 'stripe-ruby-mock', '~> 2.4.1', require: 'stripe_mock'
  gem 'vcr'
  gem 'webmock'
end
