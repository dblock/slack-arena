class ArenaFeed
  include Mongoid::Document
  include Mongoid::Timestamps

  field :arena_id, type: Integer
  field :arena_slug, type: String
  field :arena_parent, type: Hash
  field :arena_parent_at, type: DateTime

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

  # how often to refresh the channel or user (parent) being followed
  PARENT_TTL = 24 * 60 * 60

  # stop paging back through contents after this many pages
  MAX_PAGES = 10

  def sync_new_arena_items!
    started_at = Time.now.utc
    refresh_parent! if refresh_parent?
    sync!(items_since_last_sync)
    self.sync_at = started_at
    save!
  end

  def refresh_parent?
    arena_parent_at.nil? || arena_parent_at < Time.now.utc - PARENT_TTL || !v3_parent?
  end

  def refresh_parent!
    updated_parent = parent
    self.arena_parent = updated_parent.attrs.deep_symbolize_keys if updated_parent
    self.arena_parent_at = Time.now.utc
  end

  # parents stored before the v3 API migration have no type
  def v3_parent?
    arena_parent&.key?(:type)
  end

  # v3 text fields are {markdown:, html:, plain:}, v2 descriptions were in metadata
  def arena_text(value, fallback = nil)
    value.is_a?(Hash) ? value[:plain] : fallback
  end

  # v3 avatars are a URL, v2 avatars were in avatar_image
  def arena_avatar(user)
    return unless user

    user.dig(:avatar_image, :display) || (user[:avatar] if user[:avatar].is_a?(String))
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

  def sync!(items)
    items.each do |item|
      block = begin
        item.to_slack
      rescue StandardError => e
        logger.warn "Error parsing or rendering: #{e.message}\n#{item.item.to_h.to_json}"
        NewRelic::Agent.notice_error(e, custom_params: { feed: to_s })
        nil
      end
      next unless block

      begin
        message_with_channel = { attachments: [block] }.merge(channel: channel_id, as_user: true)
        logger.info "Posting '#{message_with_channel.to_json}' to #{team} on ##{channel_name}."
        team.slack_client.chat_postMessage(message_with_channel)
      rescue Slack::Web::Api::Errors::SlackError => e
        logger.warn(to_s) { e.message }
        case e.message
        when 'account_inactive', 'invalid_auth'
          deactivate_team_on_error(e.message)
        end
      rescue StandardError => e
        logger.warn("#{self}##{__method__}") { e }
        NewRelic::Agent.notice_error(e, custom_params: { feed: to_s })
      end
    end
  end

  def deactivate_team_on_error(message)
    team.deactivate!
    team.inform_everyone!(text: "There was a #{message} error posting to ##{channel_name}, please reconnect the are.na bot.")
  rescue StandardError => e
    logger.warn("#{self}##{__method__}") { e }
    NewRelic::Agent.notice_error(e, custom_params: { feed: to_s })
  end

  # Returns items newer than sync_at, newest first, or only the newest item on the first sync.
  #
  # Pages are returned newest first, but items within a page aren't always ordered, so sort them.
  def items_since_last_sync
    items = []
    (1..MAX_PAGES).each do |page|
      page_of_items = begin
        feed(page: page)
      rescue StandardError => e
        logger.warn "Error getting feed for #{self}/#{page}: #{e.message}"
        raise e
      end

      sorted = page_of_items.map { |data| ArenaItem.new(data, self) }.sort_by(&:timestamp).reverse
      return sorted.first(1) unless sync_at

      newer = sorted.reject { |item| item.timestamp < sync_at }
      items.concat(newer)
      break if newer.size < sorted.size || !page_of_items.more?
    end
    items
  end
end
