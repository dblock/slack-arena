class ArenaChannel < ArenaFeed
  def parent
    Arena.try_channel(arena_id)
  end

  def feed(options = {})
    Arena.channel_feed(arena_id, options)
  end

  def arena_channel
    arena_parent
  end

  def arena_user
    arena_channel[:user] || {}
  end

  def title
    arena_channel[:title]
  end

  def arena_user_avatar_image
    arena_user[:avatar_image] || {}
  end

  def thumb_url
    arena_user_avatar_image[:display]
  end

  def arena_url
    "https://www.are.na/#{arena_user[:slug]}/#{arena_channel[:slug]}"
  end

  def arena_channel_metadata
    arena_channel[:metadata] || {}
  end

  def description
    arena_channel_metadata[:description]
  end

  def callback_id
    persisted? ? 'disconnect' : 'connect'
  end

  def callback_action
    persisted? ? 'Disconnect' : 'Connect'
  end
end
