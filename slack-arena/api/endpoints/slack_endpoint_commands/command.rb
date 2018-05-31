module Api
  module Endpoints
    class SlackEndpointCommands
      class Command
        attr_reader :action, :arg, :channel_id, :channel_name, :user_id, :team_id, :text, :token

        def initialize(params)
          if params.key?(:payload)
            @action = params[:payload][:callback_id]
            @channel_id = params[:payload][:channel][:id]
            @channel_name = params[:payload][:channel][:name]
            @user_id = params[:payload][:user][:id]
            @team_id = params[:payload][:team][:id]
            @arg = params[:payload][:actions][0][:value]
            @token = params[:payload][:token]
            @text = [action, arg].join(' ')
          else
            @text = params[:text]
            @action, @arg = text.split(/\s/, 2)
            @channel_id = params[:channel_id]
            @channel_name = params[:channel_name]
            @user_id = params[:user_id]
            @team_id = params[:team_id]
            @token = params[:token]
          end
        end

        def user
          @user ||= ::User.find_create_or_update_by_team_and_slack_id!(
            team_id,
            user_id
          )
        end

        def bot_in_channel?
          user.team.bot_in_channel?(channel_id)
        end

        def dm?
          channel_id[0] == 'D'
        end

        def arena_feed
          return unless arg
          @arena_feed ||= case action
                          when 'connect', 'disconnect' then
                            Arena.try_channel(arg)
                          when 'follow', 'unfollow' then
                            Arena.try_user(arg)
                          else
                            invalid_command_error!
                          end
        end

        def feed_klass
          @feed_klass ||= feed_type.constantize
        end

        def feed_type
          @feed_type ||= case action
                         when 'connect', 'disconnect' then
                           'ArenaChannel'
                         when 'follow', 'unfollow' then
                           'ArenaUser'
                         else
                           invalid_command_error!
                         end
        end

        def existing_feed
          return @existing_feed if @existing_feed

          if arena_feed
            @existing_feed ||= user.team.arena_feeds.where(
              _type: feed_type,
              arena_id: arena_feed.id,
              channel_id: channel_id
            ).first
          end

          if arg
            @existing_feed ||= user.team.arena_feeds.where(
              _type: feed_type,
              arena_slug: arg,
              channel_id: channel_id
            ).first
          end

          @existing_feed
        end

        def invalid_command_error!
          raise HumanError, "I don't understand \"#{text}\", try \"#{user.team.bot_mention} help\"."
        end

        def dm_error!
          return unless dm?
          raise HumanError, "I can't do anything in a DM, sorry."
        end

        def bot_in_channel_error!
          return if bot_in_channel?
          raise SlackEndpointCommands::HumanError, "Please invite #{user.team.bot_mention} to <##{channel_id}>, first."
        end

        def slack_verification_token!
          return unless ENV.key?('SLACK_VERIFICATION_TOKEN')
          return if token == ENV['SLACK_VERIFICATION_TOKEN']
          throw :error, status: 401, message: 'Message token is not coming from Slack.'
        end

        def subscribe!
          raise SlackEndpointCommands::HumanError, "I'm already posting \"#{existing_feed.title}\" updates to <##{channel_id}>." if existing_feed
          raise SlackEndpointCommands::HumanError, "I can't find \"#{arg}\", sorry." unless arena_feed

          c = feed_klass.create!(
            channel_id: channel_id,
            channel_name: channel_name,
            created_by: user,
            arena_id: arena_feed.id,
            arena_slug: arena_feed.slug,
            arena_parent: arena_feed.attrs.deep_symbolize_keys,
            team: user.team
          )

          user.team.slack_client.chat_postMessage(
            c.connect_to_slack.merge(
              as_user: true, channel: channel_id, text: "Subscribed by #{user.slack_mention}."
            )
          )

          Api::Middleware.logger.info "SUBSCRIBE: #{c}, #{user}"

          { text: "Now posting \"#{c.title}\" updates to <##{channel_id}>.", user: user_id, channel: channel_id }
        end

        def unsubscribe!
          raise SlackEndpointCommands::HumanError, "I don't know anything about \"#{arg}\" in <##{channel_id}>, sorry." unless existing_feed

          existing_feed.destroy

          user.team.slack_client.chat_postMessage(
            existing_feed.connect_to_slack.merge(
              as_user: true, channel: channel_id, text: "Unsubscribed by #{user.slack_mention}."
            )
          )

          Api::Middleware.logger.info "UNSUBSCRIBE: #{existing_feed}, #{user}"

          { text: "No longer posting \"#{existing_feed.title}\" updates to <##{channel_id}>.", user: user_id, channel: channel_id }
        end

        def feeds(type = nil)
          Api::Middleware.logger.info "FEEDS: channel=#{channel_id} (#{channel_name}), #{user}"
          user.team.connected_feeds_to_slack(channel_id, type).merge(user: user_id)
        end

        def search
          Api::Middleware.logger.info "SEARCH: #{arg}, #{user}"
          raise SlackEndpointCommands::HumanError, 'Try searching for "something".' unless arg

          attachments = []
          %w[channel user].each do |kind|
            type = "Arena#{kind.capitalize}"
            kinds = "#{kind}s"
            results = Arena.search(arg, kind: kinds, per: 3)
            results.send(kinds).each do |result|
              feed = user.team.arena_feeds.where(_type: type, arena_id: result.id, channel_id: channel_id).first
              feed ||= type.constantize.new(
                channel_id: channel_id,
                channel_name: channel_name,
                created_by: user,
                arena_id: result.id,
                arena_slug: result.slug,
                arena_parent: result.attrs.deep_symbolize_keys,
                team: user.team
              )
              attachments << feed.connect_to_slack_attachment
            end
          end

          {
            text: "#{attachments.any? ? 'Searching' : 'No results'} for \"#{arg}\" ...",
            attachments: attachments.sort_by { |a| a[:title] || '' },
            channel: channel_id,
            user: user_id
          }
        end
      end
    end
  end
end
