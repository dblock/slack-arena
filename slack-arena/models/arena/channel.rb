module Arena
  class Channel < Arena::Base
    include Arena::Creatable
    include Arena::Connectable

    attr_reader :id, :title, :published, :open, :collaboration, :slug, :length,
                :kind, :status, :user_id, :total_pages, :current_page, :per, :follower_count

    def _class
      @attrs['class']
    end

    def _base_class
      @attrs['base_class']
    end

    def contents
      @contents ||= Array(@attrs['contents']).map { |object| Arena::Story.build_typed_object(object['class'], object) }
    end

    def collaborators
      @collaborators ||= Array(@attrs['collaborators']).map { |user| Arena::User.new(user) }
    end

    def contributors
      contents.map(&:user).uniq(&:id)
    end

    def flat_connections
      contents.flat_map(&:connections).compact.uniq(&:id)
    end

    %w[image text link media attachment channel].each do |kind|
      define_method "#{kind}s" do
        contents.select { |connectable| connectable._class.downcase == kind }
      end
    end

    def blocks
      contents.select { |connectable| connectable._base_class == 'Block' }
    end
  end
end
