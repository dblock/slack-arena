require 'time'

module Arena
  module Creatable
    def created_at
      @created_at ||= Time.parse(@attrs['created_at']) if @attrs['created_at']
    end

    def updated_at
      @updated_at ||= Time.parse(@attrs['updated_at']) if @attrs['updated_at']
    end
  end
end
