module Api
  module V2
    module Users
      class UsersController < ApplicationController
        skip_before_action :authenticate_user!, only: :subscribe

        # Create a subscription instance for the given user
        def subscribe
          if User.exists?(email: params[:user][:email])
            render json: { status: 'The email is already taken' }, status: :bad_request
          else
            subscribed_user = SubscribedUser.create!(user_params)
            if subscribed_user
              render json: { status: 'Created' }, status: :created
              # Delay the ActionCable broadcast by 10 seconds
              Thread.new do
                sleep 5
                ActionCable.server.broadcast("verification_channel_#{params[:user][:email]}", {verified: true})
              end
            else
              render json: { status: 'Something wrong happened' }, status: :bad_request
            end
          end
        rescue
          render json: { status: 'Something wrong happened' }, status: :bad_request
        end
        

        def create
          user = User.create!(user_params)
          render json: { user: user.sanitized }, status: :ok
        rescue StandardError => e
          render json: { status: 'error', cause: e }, status: :bad_request
        end

        private

        def user_params
          params.require(:user).permit(:first_name, :last_name, :email, :phone_number)
        end

      end
    end
  end
end