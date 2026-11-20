class ArenaUser < ArenaFeed
  def parent
    @parent ||= Arena.server.try_user(arena_id)
  rescue StandardError => e
    logger.warn "Error getting user #{arena_id}: #{e.message}"
    raise e
  end

  def feed(options = {})
    Arena.server.user_contents(arena_id, { sort: 'created_at_desc' }.merge(options))
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
    arena_user[:name] || arena_user[:full_name] || first_and_last_name || arena_user[:username]
  end

  def first_and_last_name
    ary = [arena_user[:first_name], arena_user[:last_name]].compact
    ary.any? ? ary.join(' ') : nil
  end

  def thumb_url
    arena_avatar(arena_user)
  end

  def arena_url
    [Arena::URL, arena_user[:slug]].compact.join('/')
  end

  def description
    arena_text(arena_user[:bio], arena_user.dig(:metadata, :description))
  end

  def callback_id
    persisted? ? 'unfollow' : 'follow'
  end

  def callback_action
    persisted? ? 'Unfollow' : 'Follow'
  end
end
