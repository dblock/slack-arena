ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

Dir[File.expand_path('config/initializers', __dir__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV['RACK_ENV']

require 'slack-ruby-bot'
require 'slack-arena/version'
require 'slack-arena/service'
require 'slack-arena/info'
require 'slack-arena/models'
require 'slack-arena/api'
require 'slack-arena/app'
require 'slack-arena/server'
require 'slack-arena/commands'
