module Arena
  class Story
    class ActionNotImplementedError < StandardError; end

    def actionable
      @actionable ||= case action
                      when 'added'
                        Arena::Added.new(self)
                      when 'followed'
                        Arena::Followed.new(self)
                      when 'commented on'
                        Arena::Commented.new(self)
                      when 'created'
                        Arena::Created.new(self)
                      when 'mentioned you'
                        Arena::Mentioned.new(self)
                      when 'is collaborating with'
                        Arena::Collaborating.new(self)
                      else
                        raise ActionNotImplementedError, action
                      end
    end
  end
end
