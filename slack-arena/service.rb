module SlackRubyBotServer
  class Service
    def self.url
      ENV['URL'] || (ENV['RACK_ENV'] == 'development' ? 'http://localhost:5000' : 'https://arena.playplay.io')
    end
  end
end
