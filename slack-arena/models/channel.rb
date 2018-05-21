class Channel
  include Mongoid::Document
  include Mongoid::Timestamps

  field :arena_id, type: Integer
  field :arena_slug, type: String
  field :title, type: String

  belongs_to :team
  belongs_to :created_by, class_name: 'User'

  field :channel_id, type: String
  field :channel_name, type: String
  field :sync_at, type: DateTime

  index({ team_id: 1, arena_id: 1, channel_id: 1 }, unique: true)

  def to_s
    "arena_id=#{arena_id}, title=#{title}, channel_id=#{channel_id}, channel_name=#{channel_name}, #{team}"
  end

  def repost!
    if sync_at
      sync_new_arena_items!
    else
      sync_last_arena_item!
    end
  end

  def channel_mention
    "<##{channel_id}>"
  end

  def sync_new_arena_items!
    sync!(stories_since_last_sync)
    update_attributes!(sync_at: Time.now.utc)
  end

  private

  def sync!(stories)
    stories.each do |story|
      story = case story.action
              when 'added' then
                Arena::Added.new(story, 'https://www.are.na/').block
              when 'followed' then
                Arena::Followed.new(story.item, 'https://www.are.na/').block
              when 'commented on' then
                Arena::Commented.new(story, 'https://www.are.na/').block
              else
                logger.warn "skipping story, #{story.action}, unsupported"
                nil
              end
      next unless story
      message_with_channel = { attachments: [story] }.merge(channel: channel_id, as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{team} on ##{channel_name}."
      team.slack_client.chat_postMessage(message_with_channel)
    end
  end

  def stories_since_last_sync
    stories = []
    page = 1
    loop do
      page_of_stories = Arena.channel_feed(arena_slug, page: page).stories
      break unless page_of_stories.any?
      page_of_stories.each do |story|
        story_ts = DateTime.rfc3339(story.created_at)
        return stories if sync_at && story_ts < sync_at
        stories << story
        break unless sync_at
      end
      page += 1
    end
    stories
  end

  def arena_channel
    @arena_channel ||= Arena.channel(arena_id)
    @arena_channel || raise("Invalid channel #{arena_id} (#{arena_slug}).")
  end
end
