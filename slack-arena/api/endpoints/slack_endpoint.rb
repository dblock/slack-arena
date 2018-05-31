require 'slack-arena/api/endpoints/slack_endpoint_commands/human_error'
require 'slack-arena/api/endpoints/slack_endpoint_commands/command'

module Api
  module Endpoints
    class SlackEndpoint < Grape::API
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
          command = SlackEndpointCommands::Command.new(params)

          command.slack_verification_token!
          command.dm_error!
          command.bot_in_channel_error!

          case command.action
          when 'search' then
            command.search
          when 'connect', 'follow' then
            command.subscribe!
          when 'disconnect', 'unfollow' then
            command.unsubscribe!
          when 'feeds' then
            command.feeds
          when 'channels' then
            command.feeds(:channel)
          when 'users' then
            command.feeds(:user)
          else
            command.invalid_command_error!
          end
        rescue SlackEndpointCommands::HumanError => e
          { text: e.message, user: command.user_id, channel: command.channel_id }
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
          command = SlackEndpointCommands::Command.new(params)

          command.slack_verification_token!
          command.dm_error!
          command.bot_in_channel_error!

          case command.action
          when 'connect', 'follow' then
            command.subscribe!
          when 'disconnect', 'unfollow'; then
            command.unsubscribe!
          else
            command.invalid_command_error!
          end
        rescue SlackEndpointCommands::HumanError => e
          { text: e.message, user: command.user_id, channel: command.channel_id }
        end
      end
    end
  end
end
