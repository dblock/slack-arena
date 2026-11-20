class ArenaChannel < ArenaFeed
  def parent
    @parent ||= Arena.server.try_channel(arena_id)
  rescue StandardError => e
    logger.warn "Error getting channel #{arena_id}: #{e.message}"
    raise e
  end

  def feed(options = {})
    Arena.server.channel_contents(arena_id, { sort: 'created_at_desc' }.merge(options))
  rescue StandardError => e
    logger.warn "Error getting channel feed #{arena_id} with #{options}: #{e.message}"
    raise e
  end

  def arena_channel
    arena_parent
  end

  # v3 channels have an owner (a user or a group), v2 channels had a user
  def arena_user
    arena_channel[:owner] || arena_channel[:user] || {}
  end

  def title
    arena_channel[:title] || 'Untitled'
  end

  def thumb_url
    arena_avatar(arena_user)
  end

  def arena_url
    [Arena::URL, arena_user[:slug], arena_channel[:slug]].compact.join('/')
  end

  def description
    arena_text(arena_channel[:description], arena_channel.dig(:metadata, :description))
  end

  def callback_id
    persisted? ? 'disconnect' : 'connect'
  end

  def callback_action
    persisted? ? 'Disconnect' : 'Connect'
  end
end
