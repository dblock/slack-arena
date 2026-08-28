module Arena
  class Story < Arena::Base
    include Arena::Creatable

    class ActionNotImplementedError < StandardError; end

    attr_reader :id, :action, :bulletin_id, :connector

    def self.build_typed_object(type, attrs)
      case type
      when 'Block'
        Arena::Block.new(attrs)
      when 'Channel'
        Arena::Channel.new(attrs)
      when 'User'
        Arena::User.new(attrs)
      when 'Comment'
        Arena::Comment.new(attrs)
      when 'Connection'
        Arena::Connection.new(attrs)
      when 'Text'
        Arena::Text.new(attrs)
      when 'Image'
        Arena::Image.new(attrs)
      when 'Link'
        Arena::Link.new(attrs)
      when 'Media'
        Arena::Media.new(attrs)
      when 'Attachment'
        Arena::Attachment.new(attrs)
      else
        Arena::Base.new(attrs)
      end
    end

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

    def user
      @user ||= Arena::User.new(@attrs['user']) if @attrs['user']
    end

    %w[item target parent].each do |method_name|
      define_method method_name do
        return if @attrs[method_name].nil?

        type = @attrs["#{method_name}_type"]
        instance_variable_get("@#{method_name}") || instance_variable_set(
          "@#{method_name}",
          self.class.build_typed_object(type, @attrs[method_name])
        )
      end
    end
  end
end
