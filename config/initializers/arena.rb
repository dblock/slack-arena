module Arena
  URL = 'https://www.are.na'.freeze

  class Client
    include HTTParty

    API_URL = 'https://api.are.na'.freeze

    def initialize(options = {})
      @access_token = options[:access_token]
      @auth_token = options[:auth_token]
    end

    def channel(id, options = {})
      Arena::Channel.new(
        legacy_channel(
          request(:get, "/v2/channels/#{id}", query: options)
        )
      )
    end

    def user(id, options = {})
      Arena::User.new(
        legacy_user(
          request(:get, "/v2/users/#{id}", query: options)
        )
      )
    end

    def channel_feed(id, options = {})
      Arena::ChannelFeed.new(
        request(:get, "/v2/channel/#{id}/feed", query: options)
      )
    end

    def user_feed(id, options = {})
      Arena::UserFeed.new(
        request(:get, "/v2/user/#{id}/feed", query: options)
      )
    end

    def search(query, options = {})
      kind = options[:kind]
      request_options = options.except(:kind)
      path = kind ? "/v2/search/#{kind}/" : '/v2/search/'

      Arena::SearchResults.new(
        request(:get, path, query: request_options.merge(q: query, kind: kind))
      )
    end

    def account_channels(options = {})
      me = request(:get, '/v3/me')
      user_id = me['id'] || me.dig('data', 'id') || raise('Missing Are.na user ID.')

      response = request(
        :get,
        "/v3/users/#{user_id}/contents",
        query: options.merge(type: 'Channel')
      )

      if response['channels']
        Arena::ChannelResults.new(response)
      else
        meta = response['meta'] || {}
        channels = Array(response['data']).filter_map do |item|
          next unless channel_payload?(item)

          legacy_channel(item)
        end

        Arena::ChannelResults.new(
          'channels' => channels,
          'current_page' => meta['current_page'],
          'total_pages' => meta['total_pages'],
          'length' => meta['total_count'] || channels.length,
          'per' => meta['per_page']
        )
      end
    end

    def channel_add_block(id, options = {})
      value = options[:source] || options[:content] || options['source'] || options['content']
      raise 'Missing Are.na block content.' unless value

      Arena::Block.new(
        legacy_block(
          request(
            :post,
            '/v3/blocks',
            body: {
              value: value,
              channel_ids: [id]
            }
          )
        )
      )
    end

    def try_channel(name, options = {})
      channel(name, options)
    rescue Arena::Error => e
      case e.message
      when /\A401:/
        # private channel, skip for now
        # https://github.com/dblock/slack-arena/issues/19
        nil
      when /\A404:/
        nil
      else
        raise e
      end
    end

    def try_user(name, options = {})
      user(name, options)
    rescue Arena::Error => e
      case e.message
      when /\A404:/
        nil
      else
        raise e
      end
    end

    private

    def request(method, path, query: nil, body: nil)
      options = { headers: request_headers }
      options[:query] = query.compact unless query.nil? || query.empty?

      if body
        options[:headers] = options[:headers].merge(
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        )
        options[:body] = JSON.generate(body)
      end

      response = self.class.send(method, "#{API_URL}#{path}", options)
      parsed = parse_response_body(response.body)

      raise Arena::Error, error_message(response, parsed) unless response.code.between?(200, 299)

      parsed
    end

    def request_headers
      return { 'Authorization' => "Bearer #{@access_token}" } if @access_token
      return { 'X-AUTH-TOKEN' => @auth_token } if @auth_token

      {}
    end

    def parse_response_body(body)
      JSON.parse(body)
    rescue JSON::ParserError, TypeError
      nil
    end

    def error_message(response, parsed)
      return "#{response.code}: Unexpected Error" if response.code == 403 && !parsed.is_a?(Hash)
      return "#{response.code}: #{response.message}" unless parsed.is_a?(Hash)

      if parsed['code'] && parsed['message'] && parsed['description']
        "#{parsed['code']}: #{parsed['message']} - #{parsed['description']}"
      elsif parsed['code'] && parsed['error'] && parsed.dig('details', 'message')
        "#{parsed['code']}: #{parsed['error']} - #{parsed.dig('details', 'message')}"
      elsif parsed['code'] && parsed['message']
        "#{parsed['code']}: #{parsed['message']}"
      elsif parsed['error'] && parsed.dig('details', 'message')
        "#{response.code}: #{parsed['error']} - #{parsed.dig('details', 'message')}"
      elsif parsed['message']
        "#{response.code}: #{parsed['message']}"
      else
        "#{response.code}: #{response.message}"
      end
    end

    def channel_payload?(payload)
      payload['type'] == 'Channel' || payload['base_type'] == 'Channel' || payload['class'] == 'Channel'
    end

    def legacy_channel(payload)
      return payload if payload['class'] == 'Channel' || payload['base_class'] == 'Channel'

      {
        'id' => payload['id'],
        'title' => payload['title'],
        'created_at' => payload['created_at'],
        'updated_at' => payload['updated_at'],
        'slug' => payload['slug'],
        'length' => payload['length'],
        'kind' => payload['kind'] || 'default',
        'status' => payload['status'] || (payload['open'] ? 'public' : 'closed'),
        'open' => payload.key?('open') ? payload['open'] : payload['status'] == 'public',
        'published' => payload.key?('published') ? payload['published'] : true,
        'collaboration' => payload['collaboration'],
        'collaborator_count' => payload['collaborator_count'],
        'user_id' => payload['user_id'] || payload.dig('user', 'id'),
        'follower_count' => payload['follower_count'],
        'metadata' => legacy_metadata(payload['metadata'] || payload['description']),
        'user' => legacy_user(payload['user']),
        'contents' => legacy_contents(payload['contents']),
        'base_class' => 'Channel',
        'class' => 'Channel'
      }.compact
    end

    def legacy_user(payload)
      return nil unless payload
      return payload if payload['class'] == 'User' || payload['base_class'] == 'User'

      full_name = payload['full_name'] || payload['username'] || payload['name']
      first_name, last_name = split_name(full_name)
      avatar = payload['avatar']

      {
        'id' => payload['id'],
        'slug' => payload['slug'],
        'username' => payload['username'] || payload['name'],
        'first_name' => payload['first_name'] || first_name,
        'last_name' => payload['last_name'] || last_name,
        'full_name' => full_name,
        'avatar' => avatar,
        'avatar_image' => payload['avatar_image'] || legacy_avatar_image(avatar),
        'channel_count' => payload['channel_count'],
        'following_count' => payload['following_count'],
        'profile_id' => payload['profile_id'],
        'follower_count' => payload['follower_count'],
        'initials' => payload['initials'],
        'metadata' => legacy_metadata(payload['metadata'] || payload['description']),
        'base_class' => 'User',
        'class' => 'User'
      }.compact
    end

    def legacy_block(payload)
      return payload if payload['class'] == 'Block' || payload['base_class'] == 'Block' || payload['base_class'] == 'Channel'

      {
        'id' => payload['id'],
        'title' => payload['title'],
        'generated_title' => payload['generated_title'],
        'created_at' => payload['created_at'],
        'updated_at' => payload['updated_at'],
        'state' => payload['state'],
        'comment_count' => payload['comment_count'],
        'content' => legacy_text_value(payload['content']),
        'content_html' => legacy_html_value(payload['content']),
        'description' => legacy_text_value(payload['description']),
        'description_html' => legacy_html_value(payload['description']),
        'source' => legacy_source(payload['source']),
        'image' => legacy_image(payload['image']),
        'attachment' => payload['attachment'],
        'embed' => payload['embed'],
        'user' => legacy_user(payload['user']),
        'base_class' => payload['base_type'] || 'Block',
        'class' => payload['type'] || payload['class'] || 'Block'
      }.compact
    end

    def legacy_contents(contents)
      return nil unless contents

      contents.map do |item|
        if channel_payload?(item)
          legacy_channel(item)
        else
          legacy_block(item)
        end
      end
    end

    def legacy_metadata(value)
      return value if value.is_a?(Hash)

      text = legacy_text_value(value)
      return nil if text.nil?

      { 'description' => text }
    end

    def legacy_avatar_image(avatar)
      return nil unless avatar

      {
        'thumb' => avatar,
        'display' => avatar
      }
    end

    def legacy_source(source)
      return source unless source.is_a?(Hash)
      return source if source['provider'].is_a?(Hash)

      {
        'url' => source['url'],
        'title' => source['title'],
        'provider' => source['provider']
      }.compact
    end

    def legacy_image(image)
      return image unless image.is_a?(Hash)
      return image if image['original'].is_a?(Hash)

      url = image['url']
      return image unless url

      {
        'thumb' => { 'url' => url },
        'square' => { 'url' => url },
        'display' => { 'url' => url },
        'large' => { 'url' => url },
        'original' => { 'url' => url }
      }
    end

    def legacy_text_value(value)
      return value unless value.is_a?(Hash)

      value['plain'] || value['markdown'] || value['html']
    end

    def legacy_html_value(value)
      return nil unless value.is_a?(Hash)

      value['html']
    end

    def split_name(full_name)
      return [nil, nil] unless full_name

      parts = full_name.split(' ', 2)
      [parts.first, parts.length > 1 ? parts.last : nil]
    end
  end
end
