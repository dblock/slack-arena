class Team
  field :api, type: Boolean, default: false

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime
  field :subscription_expired_at, type: DateTime
  field :trial_informed_at, type: DateTime

  scope :api, -> { where(api: true) }
  scope :striped, -> { where(subscribed: true, :stripe_customer_id.ne => nil) }
  scope :trials, -> { where(subscribed: false) }

  has_many :users, dependent: :destroy
  has_many :arena_feeds, dependent: :destroy

  before_validation :update_subscription_expired_at
  after_update :inform_subscribed_changed!
  after_save :inform_activated!

  def arena_channel_feeds
    arena_feeds.where(_type: 'ArenaChannel')
  end

  def arena_user_feeds
    arena_feeds.where(_type: 'ArenaUser')
  end

  def asleep?(dt = 2.weeks)
    return false unless subscription_expired?

    time_limit = Time.now - dt
    created_at <= time_limit
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: token)
  end

  def slack_channels
    slack_client.conversations_list(
      exclude_archived: true
    )['channels'].select do |channel|
      channel['is_member']
    end
  end

  def bot_in_channel?(channel_id)
    slack_client.conversations_members(channel: channel_id) do |response|
      return true if response.members.include?(bot_user_id)
    end
    false
  end

  # returns channels that were sent to
  def inform!(message)
    slack_channels.map do |channel|
      message_with_channel = message.merge(channel: channel['id'], as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{self} on ##{channel['name']}."
      rc = slack_client.chat_postMessage(message_with_channel)

      {
        ts: rc['ts'],
        channel: channel
      }
    end
  end

  # returns DM channel
  def inform_admin!(message)
    return unless activated_user_id

    channel = slack_client.conversations_open(users: activated_user_id.to_s)
    message_with_channel = message.merge(channel: channel.channel.id, as_user: true)
    logger.info "Sending DM '#{message_with_channel.to_json}' to #{activated_user_id}."
    rc = slack_client.chat_postMessage(message_with_channel)

    {
      ts: rc['ts'],
      channel: channel
    }
  end

  def inform_everyone!(message)
    inform!(message)
    inform_admin!(message)
  end

  def subscription_expired!
    return unless subscription_expired?
    return if subscription_expired_at

    inform_everyone!(text: subscribe_text)
    update_attributes!(subscription_expired_at: Time.now.utc)
  end

  def subscription_expired?
    return false if subscribed?

    time_limit = Time.now - 2.weeks
    created_at < time_limit
  end

  def subscribe_text
    [trial_expired_text, subscribe_team_text].compact.join(' ')
  end

  def update_cc_text
    "Update your credit card info at #{SlackRubyBotServer::Service.url}/update_cc?team_id=#{team_id}."
  end

  def subscribed_text
    <<~EOS.freeze
      Your team has been subscribed. Thank you!
      Follow https://twitter.com/playplayio for news and updates.
    EOS
  end

  def channels_to_slack
    result = {
      text: "To connect a channel, invite #{bot_mention} to a channel and use `/arena channels`.",
      attachments: []
    }

    if channels.any?
      channels.each do |channel|
        attachments = channel.to_slack[:attachments]
        attachments.each do |a|
          a[:text] = [a[:text], channel.channel_mention].compact.join("\n")
        end
        result[:attachments].concat(attachments)
      end
    else
      result[:text] = 'No channels connected. ' + result[:text]
    end
    result
  end

  def connected_feeds_to_slack(channel_id, type = nil)
    connected_feeds = arena_feeds.where(channel_id: channel_id)
    connected_type = "Arena#{type.capitalize}" if type
    connected_feeds = connected_feeds.where(_type: connected_type) if connected_type

    if connected_feeds.any?
      {
        text: "#{connected_feeds.count} #{type || 'feed'}#{connected_feeds.count == 1 ? '' : 's'}.",
        attachments: connected_feeds.map(&:connect_to_slack_attachment),
        channel: channel_id
      }
    else
      {
        text: "No #{type || 'feed'}s. To connect a channel or to follow a user use `/arena search` or `/arena connect|follow [channel|user]`.",
        channel: channel_id
      }
    end
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      remaining_trial_days.zero? ? 'Your trial subscription has expired.' : "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}.",
      subscribe_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

    inform_everyone!(text: trial_message)
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  private

  def trial_expired_text
    return unless subscription_expired?

    'Your trial subscription has expired and we will no longer send your Are.na channels to Slack.'
  end

  def subscribe_team_text
    "Subscribe your team for $4.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team_id} to continue receiving Are.na channels in Slack."
  end

  def inform_subscribed_changed!
    return unless subscribed? && (subscribed_changed? || saved_change_to_subscribed?)

    inform_everyone!(text: subscribed_text)
  end

  def bot_mention
    "<@#{bot_user_id || 'arena'}>"
  end

  def activated_text
    <<~EOS
      Welcome to Are.na!
      Invite #{bot_mention} to a channel to publish are.na channels to it.
    EOS
  end

  def inform_activated!
    return unless active? && activated_user_id && bot_user_id
    return unless active_changed? || activated_user_id_changed? || saved_change_to_active? || saved_change_to_activated_user_id?

    im = slack_client.conversations_open(users: activated_user_id.to_s)
    slack_client.chat_postMessage(
      text: activated_text,
      channel: im['channel']['id'],
      as_user: true
    )
  end

  def update_subscription_expired_at
    self.subscription_expired_at = nil if subscribed || subscribed_at
  end
end
