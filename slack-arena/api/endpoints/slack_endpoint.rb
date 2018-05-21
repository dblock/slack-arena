module Api
  module Endpoints
    class SlackEndpoint < Grape::API
      class HumanError < StandardError; end

      format :json

      namespace :slack do
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
          token = params['token']
          error!('Message token is not coming from Slack.', 401) if ENV.key?('SLACK_VERIFICATION_TOKEN') && token != ENV['SLACK_VERIFICATION_TOKEN']

          channel_id = params['channel_id']
          raise HumanError, "I can't do anything in a DM, sorry." if channel_id[0] == 'D'

          user_id = params['user_id']
          team_id = params['team_id']

          user = ::User.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
          raise HumanError, "Please invite #{user.team.bot_mention} to this channel before connecting an Are.na channel." unless user.team.bot_in_channel?(channel_id)

          command, channel_slug = params[:text].split(/\s/, 2)
          arena_channel = Arena.channel(channel_slug)
          existing_channel = user.team.channels.where(arena_slug: channel_slug, channel_id: channel_id).first

          case command
          when 'connect' then
            raise HumanError, "I can't find the \"#{channel_slug}\" channel, sorry." unless arena_channel
            raise HumanError, "I have already connected \"#{existing_channel.title}\" in this channel, sorry." if existing_channel

            c = Channel.create!(
              channel_id: params[:channel_id],
              channel_name: params[:channel_name],
              created_by: user,
              arena_id: arena_channel.id,
              arena_slug: arena_channel.slug,
              title: arena_channel.title,
              team: user.team
            )

            c.sync_new_arena_items!

            { text: "Successfully connected \"#{arena_channel.title}\" to <##{channel_id}>.", user: user_id, channel: channel_id }
          when 'disconnect' then
            raise HumanError, "I haven't connected the \"#{channel_slug}\" channel, sorry." unless existing_channel
            existing_channel.destroy
            { text: "Successfully disconnected \"#{arena_channel.title}\" from <##{channel_id}>.", user: user_id, channel: channel_id }
          else
            raise HumanError, "I don't understand \"#{params[:text]}\", try \"#{user.team.bot_mention} help\"."
          end
        rescue HumanError => e
          { text: e.message, user: user_id, channel: channel_id }
        end
      end
    end
  end
end
