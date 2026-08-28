require 'time'

module Arena
  module Connectable
    def user
      @user ||= Arena::User.new(@attrs['user']) if @attrs['user']
    end

    %w[position selected connection_id].each do |method_name|
      define_method method_name do
        instance_variable_get("@#{method_name}") || instance_variable_set("@#{method_name}", @attrs[method_name])
      end
    end

    %w[image text link media attachment channel].each do |kind|
      define_method "is_#{kind}?" do
        _class == kind.capitalize
      end
    end

    %w[image attachment embed].each do |kind|
      define_method "has_#{kind}?" do
        !@attrs[kind].nil?
      end
    end

    def block?
      _base_class == 'Block'
    end

    def connections
      @connections ||= Array(@attrs['connections']).map { |channel| Arena::Channel.new(channel) }
    end

    def connected_at
      @connected_at ||= Time.parse(@attrs['connected_at']) if @attrs['connected_at']
    end

    def connected_by_different_user?
      user.id != connected_by.id
    end

    def connected_by
      return unless @attrs['connected_at']

      @connected_by ||= Arena::User.new(
        'id' => @attrs['connected_by_user_id'],
        'username' => @attrs['connected_by_username'],
        'full_name' => @attrs['connected_by_username']
      )
    end
  end
end
