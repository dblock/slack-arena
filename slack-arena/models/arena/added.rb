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
    def author
      item&.user
    end

    def author_url
      [Arena::URL, author&.slug].compact.join('/')
    end

    def author_name
      author&.full_name || author&.username
    end

    def author_avatar
      author.image&.original&.url if author&.has_image?
    end

    def item_title
      item&.title
    end

    def item_image
      item.image&.original&.url if item&.has_image?
    end

    def target_url
      [Arena::URL, target&.user&.slug, target&.slug].compact.join('/')
    end

    def target_title
      target&.title
    end

    def item_url
      case item
      when Arena::Channel
        [author_url, item&.slug].compact.join('/')
      when Arena::Block
        [Arena::URL, 'block', item&.id].compact.join('/')
      end
    end

    def to_s
      case item
      when Arena::Channel
        "Connected to <#{target_url}|#{target_title}>."
      when Arena::Block
        "Added to <#{target_url}|#{target_title}>."
      end
    end

    def to_slack
      {
        author_name: author_name,
        author_link: author_url,
        text: to_s,
        image_url: item_image,
        title: item_title,
        title_link: item_url
      }
    end
  end
end
