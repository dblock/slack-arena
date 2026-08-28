module Arena
  class Entity
    class Image < Arena::Entity
      include Arena::Creatable

      attr_reader :filename, :content_type

      %w[thumb square display large original].each do |method_name|
        define_method method_name do
          instance_variable_get("@#{method_name}") || instance_variable_set("@#{method_name}", Arena::Entity::Version.new(@attrs[method_name]))
        end
      end
    end
  end
end
