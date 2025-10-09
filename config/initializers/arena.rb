module Arena
  URL = 'https://www.are.na'.freeze

  class Client
    logger(::Logger.new($stdout))

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

    def try_user(name, options = {})
      user(name, options)
    rescue Arena::Error => e
      case e.message
      when '404: Not Found - The resource you are looking for does not exist.'
        nil
      else
        raise e
      end
    end
  end

  class Base
    def initialize(attrs = {})
      Api::Middleware.logger.debug attrs
      @attrs = attrs
    end
  end
end
