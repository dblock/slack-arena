class ArenaUser < ArenaFeed
  def parent
    @parent ||= Arena.try_user(arena_id)
  rescue StandardError => e
    logger.warn "Error getting user #{arena_id}: #{e.message}"
    raise e
  end

  def feed(options = {})
    Arena.user_feed(arena_id, { per: 50 }.merge(options))
  rescue StandardError => e
    logger.warn "Error getting user feed #{arena_id} with #{options}: #{e.message}"
    raise e
  end

  def arena_user
    arena_parent
  end

  def title
    display_name || 'Anonymous'
  end

  def display_name
    arena_user[:full_name] || first_and_last_name || arena_user[:username]
  end

  def first_and_last_name
    ary = [arena_user[:first_name], arena_user[:last_name]].compact
    ary.any? ? ary.join(' ') : nil
  end

  def arena_user_avatar_image
    arena_user[:avatar_image] || {}
  end

  def thumb_url
    arena_user_avatar_image[:display]
  end

  def arena_url
    "https://www.are.na/#{arena_user[:slug]}"
  end

  def arena_user_metadata
    arena_user[:metadata] || {}
  end

  def description
    arena_user_metadata[:description]
  end

  def callback_id
    persisted? ? 'unfollow' : 'follow'
  end

  def callback_action
    persisted? ? 'Unfollow' : 'Follow'
  end
end
