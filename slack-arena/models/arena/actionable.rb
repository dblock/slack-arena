module Arena
  class Actionable
    attr_reader :story

    def initialize(story)
      @story = story
    end

    # item: story.item

    def item
      story.item
    end

    # target: story.target

    def target
      story.target
    end

    # misc

    def to_slack
      nil
    end
  end
end
