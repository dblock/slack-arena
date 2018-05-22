module Arena
  class Story
    # class ActionNotImplementedError < StandardError; end

    def actionable
      @actionable ||= case action
                      when 'added' then
                        Arena::Added.new(self)
                      end
      # when 'followed' then
      #   Arena::Followed.new(self)
      # when 'commented on' then
      #   Arena::Commented.new(self)
      # when 'created' then
      #   Arena::Created.new(self)
      # when 'mentioned you' then
      #   Arena::Mentioned.new(self)
      # when 'is collaborating with' then
      #   Arena::Collaborating.new(self)
      # else
      #   raise ActionNotImplementedError, action
      # end
    end
  end
end
