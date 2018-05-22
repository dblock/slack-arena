module Arena
  class Actionable
    attr_reader :story

    def initialize(story)
      @story = story
    end

    def block
      nil
    end
  end
end
