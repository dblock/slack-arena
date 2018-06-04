class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :is_bot, type: Boolean

  field :arena_token, type: String
  field :arena_token_scope, type: String
  field :arena_token_type, type: String
  field :arena_token_at, type: DateTime

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)

  # Are.na

  def connected_to_arena?
    !arena_token.nil?
  end

  def connect_redirect_url
    "#{ENV['APP_URL'] || SlackArena::Service.url}/connect"
  end

  def connect_to_arena_url(channel_id)
    state = [id.to_s, channel_id].join(',')
    "https://dev.are.na/oauth/authorize?client_id=#{ENV['ARENA_CLIENT_ID']}&redirect_uri=#{connect_redirect_url}&response_type=code&state=#{state}"
  end

  def connect_to_arena_to_slack(channel_id)
    url = connect_to_arena_url(channel_id)
    {
      text: 'Please connect your Are.na account.', attachments: [
        fallback: "Please connect your Are.na account at #{url}.",
        actions: [
          type: 'button',
          text: 'Click Here',
          url: url
        ]
      ]
    }
  end

  def connect!(code, channel_id)
    rc = HTTParty.post('https://dev.are.na/oauth/token',
                       body: {
                         client_id: ENV['ARENA_CLIENT_ID'],
                         client_secret: ENV['ARENA_CLIENT_SECRET'],
                         code: code,
                         grant_type: 'authorization_code',
                         redirect_uri: connect_redirect_url
                       },
                       haeders: {
                         'Content-Type' => 'application/json'
                       })
    raise "Are.na returned #{rc.code}: #{rc.message}" unless rc.code == 200

    body = JSON.parse(rc.body)
    update_attributes!(
      arena_token: body['access_token'],
      arena_token_at: Time.at(body['created_at']),
      arena_token_type: body['token_type'],
      arena_token_scope: body['scope']
    )

    logger.info "Connected team=#{team_id}, user=#{user_name}, user_id=#{id} to are.na."

    team.slack_client.chat_postEphemeral(
      user: user_id,
      text: 'Successfully connected your Are.na account.',
      channel: channel_id
    )

    raise "#{rc.code}: #{rc.message}" unless rc.code == 200
  end

  def arena_client
    raise 'Missing Are.na access token.' unless arena_token
    @arena_client ||= Arena::Client.new(access_token: arena_token)
  end

  # Slack

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention!(team, user_name)
    query = user_name =~ /^<@(.*)>$/ ? { user_id: ::Regexp.last_match[1] } : { user_name: ::Regexp.new("^#{user_name}$", 'i') }
    user = User.where(query.merge(team: team)).first
    raise SlackArena::Error, "I don't know who #{user_name} is!" unless user
    user
  end

  def self.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
    team = Team.where(team_id: team_id).first || raise("Cannot find team ID #{team_id}")
    user = User.where(team: team, user_id: user_id).first || User.create!(team: team, user_id: user_id)
    user
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name, is_bot: instance_info.is_bot) if instance && (instance.user_name != instance_info.name || instance.is_bot != instance_info.is_bot)
    instance ||= User.create!(team: client.owner, user_id: slack_id, user_name: instance_info.name, is_bot: instance_info.is_bot)
    instance
  end

  def inform!(message)
    team.slack_channels.map { |channel|
      next if user_id && !user_in_channel?(channel['id'])
      message_with_channel = message.merge(channel: channel['id'], as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{team} on ##{channel['name']}."
      rc = team.slack_client.chat_postMessage(message_with_channel)

      {
        ts: rc['ts'],
        channel: channel
      }
    }.compact
  end

  def to_s
    "user_id=#{user_id}, user_name=#{user_name}"
  end

  def dm!(message)
    im = team.slack_client.im_open(user: user_id)
    team.slack_client.chat_postMessage(message.merge(channel: im['channel']['id'], as_user: true))
  end

  def user_in_channel?(channel_id)
    team.slack_client.conversations_members(channel: channel_id) do |response|
      return true if response.members.include?(user_id)
    end
    false
  end
end
