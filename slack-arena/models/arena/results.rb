module Arena
  class Results < Arena::Base
    attr_reader :length, :total_pages, :current_page, :per
  end

  class ChannelResults < Results
    def channels
      @channels ||= Array(@attrs['channels']).map { |channel| Arena::Channel.new(channel) }
    end
  end
end
