module Arena
  class Created < Actionable
    def author
      item.user
    end

    def author_url
      [Arena::URL, author.slug].compact.join('/')
    end

    def author_name
      author.full_name || author.username
    end

    def channel
      item
    end

    def channel_name
      channel.title
    end

    def channel_link
      [Arena::URL, channel.user.slug, channel.slug].compact.join('/')
    end

    def to_slack
      {
        author_name: author_name,
        author_link: author_url,
        title: channel_name,
        title_link: channel_link
      }
    end
  end
end
