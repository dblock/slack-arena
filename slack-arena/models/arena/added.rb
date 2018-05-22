module Arena
  #
  # Refers to a connection to a channel.
  #
  # Item can either be a Channel or a Block.
  # Connector will always be "to".
  # Target will always be a Channel.
  #
  # This feed item will also have a parent attribute that will contain the connection record.
  #
  class Added < Actionable
    def block_author
      target = story.target
      block = story.item
      if block.has_image? || block._class == 'Text'
        [story.user.slug, target.slug].compact.join('/')
      else
        [target.user.slug, target.slug].compact.join('/')
      end
    end

    def block_channel_fields
      return unless story.item._class == 'Channel'
      [
        {
          title: 'Blocks',
          value: story.item.length,
          short: true
        },
        {
          title: 'Followers',
          value: story.item.follower_count,
          short: true
        }
      ]
    end

    def block_image
      story.item.image.original.url if story.item.has_image?
    end

    def block_text_source
      if story.item.source
        story.item.source.url
      else
        story.item.image.original.url
      end
    end

    def block_text
      if story.item.has_image?
        story.item.source.url if block_text_source.include? 'twitter.com'
      elsif story.item._class == 'Text'
        story.item.content
      end
    end

    def block_title_link_image
      if story.item.source
        story.item.source.url
      else
        story.item.image.original.url
      end
    end

    def block_title_link_alt
      block = story.item
      if block._class == 'Channel'
        [block.user.slug, block.slug].compact.join('/')
      elsif block._class == 'Text'
        ['block', block.id.to_s].compact.join('/')
      end
    end

    def block_title_link
      if story.item.has_image?
        block_title_link_image
      else
        [Arena::URL, block_title_link_alt].compact.join('/')
      end
    end

    def block_status_color
      return unless story.item._class == 'Channel'
      case story.item.status
      when 'public' then
        '#17ac10'
      when 'private' then
        '#b60202'
      else
        '#4b3d67'
      end
    end

    def block_title
      if story.item._class == 'Channel'
        "#{story.item.title}, by #{story.item.user.full_name}"
      else
        story.item.title
      end
    end

    def block
      {
        author_name: "Connected to #{story.target.title}",
        author_link: [Arena::URL, block_author].compact.join('/'),
        color: block_status_color,
        fields: block_channel_fields,
        image_url: block_image,
        text: block_text,
        title: block_title,
        title_link: block_title_link
      }
    end
  end
end
