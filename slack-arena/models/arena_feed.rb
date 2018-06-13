class ArenaFeed
  include Mongoid::Document
  include Mongoid::Timestamps

  field :arena_id, type: Integer
  field :arena_slug, type: String
  field :arena_parent, type: Hash

  belongs_to :team
  belongs_to :created_by, class_name: 'User'

  field :channel_id, type: String
  field :channel_name, type: String
  field :sync_at, type: DateTime

  index({ _type: 1, team_id: 1, arena_id: 1, channel_id: 1 }, unique: true)

  def to_s
    "_type=#{self.class.name}, arena_id=#{arena_id}, title=#{title}, channel_id=#{channel_id}, channel_name=#{channel_name}, #{team}"
  end

  def channel_mention
    "<##{channel_id}>"
  end

  def parent
    raise NotImplementedError
  end

  def feed(_options = {})
    raise NotImplementedError
  end

  def title
    raise NotImplementedError
  end

  def thumb_url
    raise NotImplementedError
  end

  def arena_url
    raise NotImplementedError
  end

  def description
    raise NotImplementedError
  end

  def sync_new_arena_items!
    updated_parent = parent
    self.arena_parent = updated_parent.attrs.deep_symbolize_keys if updated_parent
    sync!(stories_since_last_sync)
    self.sync_at = Time.now.utc
    save!
  end

  def to_slack_attachment
    {
      title: title,
      title_link: arena_url,
      text: description,
      thumb_url: thumb_url,
      color: '#000000'
    }
  end

  def class_id
    self.class.name.gsub(/^Arena/, '').downcase
  end

  def callback_id
    raise NotImplementedError
  end

  def connect_action
    raise NotImplementedError
  end

  def connect_to_slack_attachment
    to_slack_attachment.merge(
      callback_id: callback_id,
      actions: [{
        name: 'arena_id',
        text: callback_action,
        type: 'button',
        value: arena_id
      }]
    )
  end

  def connect_to_slack
    {
      attachments: [
        connect_to_slack_attachment
      ]
    }
  end

  def to_slack
    {
      attachments: [
        to_slack_attachment
      ]
    }
  end

  private

  def sync!(stories)
    stories.each do |story|
      block = begin
        story.actionable.to_slack
      rescue Arena::Story::ActionNotImplementedError => e
        logger.warn "ActionNotImplementedError: #{e.message}"
        nil
      end
      next unless block
      message_with_channel = { attachments: [block] }.merge(channel: channel_id, as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{team} on ##{channel_name}."
      team.slack_client.chat_postMessage(message_with_channel)
    end
  end

  def stories_since_last_sync
    stories = []
    page = 1
    loop do
      page_of_stories = begin
        feed(page: page).stories
      rescue StandardError => e
        logger.warn "Error getting feed for #{self}/#{page}: #{e.message}"
        raise e
      end
      break unless page_of_stories.any?
      page_of_stories.each do |story|
        story_ts = DateTime.rfc3339(story.created_at)
        return stories if sync_at && story_ts < sync_at
        stories << story
        break unless sync_at
      end
      break unless sync_at
      page += 1
    end
    stories
  end
end
