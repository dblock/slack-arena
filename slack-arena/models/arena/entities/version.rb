module Arena
  class Entity
    class Version < Arena::Entity
      attr_reader :url, :file_size, :file_size_display
    end
  end
end
