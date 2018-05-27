module Arena
  class Commented < Actionable
    def to_s
      story.item.body
    end

    def user
      story.user
    end

    def user_name
      user.full_name
    end

    def user_url
      [Arena::URL, user.slug].compact.join('/')
    end

    def target_title
      target.title
    end

    def target_url
      [Arena::URL, 'block', target.id].compact.join('/')
    end

    def to_slack
      {
        author_name: user_name,
        author_link: user_url,
        text: to_s,
        title: target_title,
        title_link: target_url
      }
    end
  end
end
