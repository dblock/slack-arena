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
          requires :team_id, type: String
        end
        post '/command' do
          token = params['token']
          error!('Message token is not coming from Slack.', 401) if ENV.key?('SLACK_VERIFICATION_TOKEN') && token != ENV['SLACK_VERIFICATION_TOKEN']

          channel_id = params['channel_id']
          user_id = params['user_id']
          team_id = params['team_id']

          user = ::User.find_create_or_update_by_team_and_slack_id!(team_id, user_id)

          result = if channel_id[0] == 'D'
                     { text: "I can't do anything in a DM, sorry." }
                   elsif !user.team.bot_in_channel?(channel_id)
                     { text: "Please invite #{user.team.bot_mention} to this channel before connecting an Are.na channel." }
                   else
                     { text: 'TODO' }
                   end

          result.merge(
            user: user_id, channel: channel_id
          )
        end
      end
    end
  end
end
