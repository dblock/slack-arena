module Api
  module Endpoints
    class SlackEndpoint < Grape::API
      class HumanError < StandardError; end

      format :json

      namespace :slack do
        before do
          token = params[:token]
          error!('Message token is not coming from Slack.', 401) if ENV.key?('SLACK_VERIFICATION_TOKEN') && token != ENV['SLACK_VERIFICATION_TOKEN']
        end

        desc 'Respond to slash commands.'
        params do
          requires :command, type: String
          requires :text, type: String
          requires :token, type: String
          requires :user_id, type: String
          requires :channel_id, type: String
          requires :channel_name, type: String
          requires :team_id, type: String
        end
        post '/command' do
          channel_id = params[:channel_id]
          channel_name = params[:channel_name]
          raise HumanError, "I can't do anything in a DM, sorry." if channel_id[0] == 'D'

          user_id = params[:user_id]
          team_id = params[:team_id]

          user = ::User.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
          raise HumanError, "Please invite #{user.team.bot_mention} to <##{channel_id}>, first." unless user.team.bot_in_channel?(channel_id)

          command, channel_slug = params[:text].split(/\s/, 2)
          arena_channel = Arena.try_channel(channel_slug) if channel_slug
          existing_channel = user.team.channels.where(arena_id: arena_channel.id, channel_id: channel_id).first if arena_channel
          existing_channel ||= user.team.channels.where(arena_slug: channel_slug, channel_id: channel_id).first if channel_slug

          case command
          when 'search' then
            Api::Middleware.logger.info "SEARCH: #{channel_slug}, #{user}"
            raise HumanError, 'Try searching for "something".' unless channel_slug

            search_results = Arena.search(channel_slug).channels.take(5).map do |r|
              c = user.team.channels.where(arena_id: r.id, channel_id: channel_id).first
              c ||= Channel.new(
                channel_id: channel_id,
                channel_name: channel_name,
                created_by: user,
                arena_id: r.id,
                arena_slug: r.slug,
                arena_channel: r.attrs.deep_symbolize_keys,
                team: user.team
              )
              c.connect_to_slack_attachment
            end

            {
              text: "#{search_results.any? ? 'Searching' : 'No results'} for \"#{channel_slug}\" ...",
              attachments: search_results,
              channel: channel_id,
              user: user_id
            }
          when 'connect' then
            raise HumanError, "I have already connected \"#{existing_channel.title}\" to <##{channel_id}>, sorry." if existing_channel
            raise HumanError, "I can't find the \"#{channel_slug}\" channel, sorry." unless arena_channel

            c = Channel.create!(
              channel_id: channel_id,
              channel_name: channel_name,
              created_by: user,
              arena_id: arena_channel.id,
              arena_slug: arena_channel.slug,
              arena_channel: arena_channel.attrs.deep_symbolize_keys,
              team: user.team
            )

            user.team.slack_client.chat_postMessage(
              c.connect_to_slack.merge(
                as_user: true, channel: channel_id, text: "A channel was connected by #{user.slack_mention}."
              )
            )

            Api::Middleware.logger.info "CONNECT: #{c}, #{user}"

            { text: "Successfully connected \"#{arena_channel.title}\" to <##{channel_id}>.", user: user_id, channel: channel_id }
          when 'disconnect' then
            raise HumanError, "I haven't connected \"#{channel_slug}\" to <##{channel_id}>, sorry." unless existing_channel

            user.team.slack_client.chat_postMessage(
              existing_channel.connect_to_slack.merge(
                as_user: true, channel: channel_id, text: "A channel was disconnected by #{user.slack_mention}."
              )
            )

            existing_channel.destroy

            Api::Middleware.logger.info "DISCONNECT: #{existing_channel}, #{user}"

            { text: "Successfully disconnected \"#{existing_channel.title}\" from <##{channel_id}>.", user: user_id, channel: channel_id }
          when 'channels' then
            Api::Middleware.logger.info "CHANNELS: channel=#{channel_id} (#{channel_name}), #{user}"
            user.team.connected_channels_to_slack(channel_id)
          else
            raise HumanError, "I don't understand \"#{params[:text]}\", try \"#{user.team.bot_mention} help\"."
          end
        rescue HumanError => e
          { text: e.message, user: user_id, channel: channel_id }
        end

        desc 'Respond to interactive slack buttons and actions.'
        params do
          requires :payload, type: JSON do
            requires :token, type: String
            requires :callback_id, type: String
            requires :channel, type: Hash do
              requires :id, type: String
            end
            requires :user, type: Hash do
              requires :id, type: String
            end
            requires :team, type: Hash do
              requires :id, type: String
            end
            requires :actions, type: Array do
              requires :value, type: String
            end
          end
        end
        post '/action' do
          payload = params[:payload]

          callback_id = payload[:callback_id]
          channel_id = payload[:channel][:id]
          channel_name = payload[:channel][:name]
          user_id = payload[:user][:id]
          team_id = payload[:team][:id]

          user = ::User.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
          raise HumanError, "Please invite #{user.team.bot_mention} to <##{channel_id}>, first." unless user.team.bot_in_channel?(channel_id)

          arena_channel_id = payload[:actions][0][:value]
          arena_channel = Arena.try_channel(arena_channel_id) if arena_channel_id
          arena_channel_title = arena_channel.title if arena_channel
          existing_channel = user.team.channels.where(arena_id: arena_channel_id, channel_id: channel_id).first if arena_channel_id

          case callback_id
          when 'connect-channel' then
            raise HumanError, "I have already connected \"#{existing_channel.title}\" to <##{channel_id}>, sorry." if existing_channel
            raise HumanError, "I can't find the \"#{arena_channel_id}\" channel, sorry." unless arena_channel

            c = Channel.create!(
              channel_id: channel_id,
              channel_name: channel_name,
              created_by: user,
              arena_id: arena_channel.id,
              arena_slug: arena_channel.slug,
              arena_channel: arena_channel.attrs.deep_symbolize_keys,
              team: user.team
            )

            user.team.slack_client.chat_postMessage(
              c.connect_to_slack.merge(
                as_user: true, channel: channel_id, text: "A channel was connected by #{user.slack_mention}."
              )
            )

            Api::Middleware.logger.info "CONNECT: #{c}, #{user}, #{user.team}"
            user.team.connected_channels_to_slack(channel_id).merge(user: user_id)
          when 'disconnect-channel' then
            raise HumanError, "I have not connected \"#{arena_channel_title || arena_channel_id}\" to <##{channel_id}>, sorry." unless existing_channel
            existing_channel.destroy
            Api::Middleware.logger.info "DISCONNECT: #{existing_channel}, #{user}, #{user.team}."

            user.team.slack_client.chat_postMessage(
              existing_channel.connect_to_slack.merge(
                as_user: true, channel: channel_id, text: "A channel was disconnected by #{user.slack_mention}."
              )
            )

            user.team.connected_channels_to_slack(channel_id).merge(user: user_id)
          else
            raise HumanError, "I don't understand \"#{callback_id}\", sorry."
          end
        rescue HumanError => e
          { text: e.message, user: user_id, channel: channel_id }
        end
      end
    end
  end
end
