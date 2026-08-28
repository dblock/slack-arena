module Arena
  class SearchResults < Arena::Base
    attr_reader :term, :per, :current_page, :total_pages, :length, :authenticated

    %w[user channel block].each do |type|
      define_method "#{type}s" do
        instance_variable_get("@#{type}s") || instance_variable_set(
          "@#{type}s",
          Array(@attrs["#{type}s"]).map { |element| Arena::Story.build_typed_object(type.capitalize, element) }
        )
      end
    end
  end
end
