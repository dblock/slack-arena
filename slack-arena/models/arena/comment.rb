module Arena
  class Comment < Arena::Base
    include Arena::Creatable

    attr_reader :id, :commentable_id, :commentable_type, :body

    def _class
      @attrs['class']
    end

    def user
      @user ||= Arena::User.new(@attrs['user']) if @attrs['user']
    end
  end
end
