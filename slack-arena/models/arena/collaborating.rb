module Arena
  class Collaborating < Actionable
    def to_s
      "<#{user_url}|#{user_name}> added <#{collaborator_url}|#{collaborator_name}> as collaborator to <#{target_url}|#{target_title}>."
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
      [user_url, target.slug].compact.join('/')
    end

    def collaborator_name
      item.full_name
    end

    def collaborator_url
      [Arena::URL, item.slug].compact.join('/')
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
