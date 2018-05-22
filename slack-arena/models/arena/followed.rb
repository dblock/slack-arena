module Arena
  #
  # Refers to a user following either a channel or another user.
  #
  # Item can either be a User or a Channel.
  #
  class Followed < Actionable
    def block_thumb
      return if defined?(story.title)
      story.user.avatar_image.display
    end

    def block_title
      if defined?(story.title)
        "#{story.title}, by #{story.user.full_name}"
      else
        story.user.full_name
      end
    end

    def block_fields_block_type
      if defined?(story.title)
        'Blocks'
      else
        'Channels'
      end
    end

    def block_fields_block_count
      if defined?(story.title)
        story.length
      elsif story.is_a?(Arena::User)
        story.item.channel_count
      else
        story.item.follower_count
      end
    end

    def block_fields
      followers_count = {
        title: 'Followers',
        value: story.item.follower_count,
        short: true
      }

      [{
        title: block_fields_block_type,
        value: block_fields_block_count,
        short: true
      }, followers_count]
    end

    def block_color
      return unless defined?(story.title)
      case story.item.status
      when 'public' then
        '#17ac10'
      when 'private' then
        '#b60202'
      else
        '#4b3d67'
      end
    end

    def block_title_link
      case story.item
      when Arena::Channel then
        [Arena::URL, story.item.user.slug, story.item.slug].compact.join('/')
      else
        [Arena::URL, story.item.slug].compact.join('/')
      end
    end

    def block
      {
        author_name: 'Followed',
        thumb_url: block_thumb,
        title_link: block_title_link,
        title: block_title,
        fields: block_fields,
        color: block_color
      }
    end
  end
end
