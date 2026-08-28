module Arena
  class ChannelFeed < Arena::Base
    attr_reader :type, :limit, :total, :offset, :range_start, :range_end

    def stories
      @stories ||= Array(@attrs['items']).map { |item| Arena::Story.new(item) }
    end

    alias items stories
  end
end
