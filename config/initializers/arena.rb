Arena.configure do |config|
  config.user_agent = 'slack-arena (+https://arena.playplay.io)'
  # the arena gem defaults access_token to ARENA_ACCESS_TOKEN, keep it for v3 reads only (see Arena.server)
  config.access_token = nil
end

module Arena
  URL = 'https://www.are.na'.freeze

  # Are.na v3 API client for server-side reads, authenticated with ARENA_ACCESS_TOKEN when set.
  def self.server
    Arena.v3(access_token: ENV.fetch('ARENA_ACCESS_TOKEN', nil))
  end

  # Are.na v2 API client, still used for search and for posting blocks on behalf of users.
  class Client
    def try_channel(name, options = {})
      channel(name, options)
    rescue Arena::Error => e
      case e.message
      when '401: Unauthorized - Invalid credentials.'
        # private channel, skip for now
        # https://github.com/dblock/slack-arena/issues/19
        nil
      when '404: Not Found - The resource you are looking for does not exist.'
        nil
      else
        raise e
      end
    end
  end

  module V3
    class Client
      # Returns nil for channels that don't exist or that are private.
      def try_channel(id)
        channel(id)
      rescue Arena::V3::NotFoundError, Arena::V3::UnauthorizedError, Arena::V3::ForbiddenError
        nil
      end

      # Returns nil for users that don't exist.
      def try_user(id)
        user(id)
      rescue Arena::V3::NotFoundError
        nil
      end
    end
  end
end
