module Api
  module Endpoints
    class UsersEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :users do
        desc 'Connect a user to Are.na.'
        params do
          requires :id, type: String
          requires :code, type: String
          requires :channel_id, type: String
        end
        put ':id' do
          user = User.where(id: params[:id]).first
          if user
            user.connect!(params[:code], params[:channel_id])
          else
            error!('Missing User', 404)
          end

          present user, with: Api::Presenters::UserPresenter
        end
      end
    end
  end
end
