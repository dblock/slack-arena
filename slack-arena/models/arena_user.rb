class ArenaUser < ArenaFeed
  def parent
    Arena.try_user(arena_id)
  end

  def feed(options = {})
    Arena.user_feed(arena_id, { per: 50 }.merge(options))
  end

  def arena_user
    arena_parent
  end

  def title
    arena_user[:full_name]
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
