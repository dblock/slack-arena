module SlackArena
  class Server < SlackRubyBotServer::Server
    on :channel_joined do |client, data|
      message = 'Welcome to Are.na! Please `/arena connect [channel]` to publish a channel here.'
      logger.info "#{client.owner.name}: joined ##{data.channel['name']}."
      client.say(channel: data.channel['id'], text: message)
    end

    on :user_change do |client, data|
      user = User.where(team: client.owner, user_id: data.user.id).first
      next unless user && user.user_name != data.user.name
      logger.info "RENAME: #{user.user_id}, #{user.user_name} => #{data.user.name}"
      user.update_attributes!(user_name: data.user.name)
    end
  end
end
