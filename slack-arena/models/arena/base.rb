module Arena
  class Base
    INTEGER_ATTR_PATTERN = /\A(id|.*_id|.*_count|length|per|position|offset|limit|total_pages|current_page)\z/

    attr_reader :attrs

    alias to_hash attrs

    def self.attr_reader(*attrs)
      attrs.each do |attribute|
        define_method attribute do
          value = @attrs[attribute.to_s]
          if attribute.to_s.match?(INTEGER_ATTR_PATTERN) && value.is_a?(String) && value.match?(/\A\d+\z/)
            value.to_i
          else
            value
          end
        end
      end
    end

    def initialize(attrs = {})
      @attrs = attrs || {}
    end
  end
end
