module Arena
  class Entity
    class Source < Arena::Entity
      attr_reader :url, :title

      def provider
        @provider ||= Arena::Entity::Provider.new(@attrs['provider']) if @attrs['provider']
      end
    end
  end
end
