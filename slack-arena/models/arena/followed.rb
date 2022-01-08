module Arena
  #
  # Refers to a user following either a channel or another user&.
  #
  # Item can either be a User or a Channel.
  #
  class Followed < Actionable
    def to_s
      "<#{user_url}|#{user_name}> followed <#{followed_url}|#{followed_name_or_title}>."
    end

    def user
      story&.user
    end

    def user_name
      user&.full_name
    end

    def user_url
      [Arena::URL, user&.slug].compact.join('/')
    end

    def followed
      story&.item
    end

    def followed_name_or_title
      case item
      when Arena::Channel
        item&.title
      when Arena::User
        item&.full_name
      end
    end

    def followed_url
      case item
      when Arena::Channel
        [Arena::URL, item&.user&.slug, item&.slug].compact.join('/')
      when Arena::User
        [Arena::URL, item&.slug].compact.join('/')
      end
    end

    def to_slack
      {
        author_name: user_name,
        author_link: user_url,
        text: to_s,
        title: followed_name_or_title,
        title_link: followed_url
      }
    end
  end
end
