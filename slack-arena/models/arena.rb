require 'slack-arena/models/arena/error'
require 'slack-arena/models/arena/base'
require 'slack-arena/models/arena/creatable'
require 'slack-arena/models/arena/connectable'
require 'slack-arena/models/arena/entity'
require 'slack-arena/models/arena/entities/version'
require 'slack-arena/models/arena/entities/provider'
require 'slack-arena/models/arena/entities/avatar'
require 'slack-arena/models/arena/entities/source'
require 'slack-arena/models/arena/entities/image'
require 'slack-arena/models/arena/entities/attachment'
require 'slack-arena/models/arena/entities/embed'
require 'slack-arena/models/arena/user'
require 'slack-arena/models/arena/connection'
require 'slack-arena/models/arena/comment'
require 'slack-arena/models/arena/block'
require 'slack-arena/models/arena/channel'
require 'slack-arena/models/arena/results'
require 'slack-arena/models/arena/search_results'
require 'slack-arena/models/arena/channel_feed'
require 'slack-arena/models/arena/user_feed'
require 'slack-arena/models/arena/actionable'
require 'slack-arena/models/arena/added'
require 'slack-arena/models/arena/collaborating'
require 'slack-arena/models/arena/commented'
require 'slack-arena/models/arena/created'
require 'slack-arena/models/arena/followed'
require 'slack-arena/models/arena/mentioned'
require 'slack-arena/models/arena/story'

module Arena
  class << self
    def client
      @client ||= Arena::Client.new
    end

    def reset_client!
      @client = nil
    end

    private

    def method_missing(method_name, ...)
      return client.public_send(method_name, ...) if client.respond_to?(method_name)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name) || super
    end
  end
end
