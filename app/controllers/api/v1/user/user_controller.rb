# frozen_string_literal: true

module Api
  module V1
    module User
      # Handles the users related calls
      class UserController < Api::V1::BaseController
        skip_before_action :active_user?,
                           only: %i[change_password
                                    modify_password
                                    subscribe
                                    verify_availability
                                    return_subscribed_info
                                    send_payment_status
                                    retrieve_dealer
                                    create_dealer
                                    update_dealer
                                    log_out
                                    me]
        skip_before_action :doorkeeper_authorize!,
                           only: %i[change_password
                                    modify_password
                                    subscribe
                                    verify_availability
                                    return_subscribed_info
                                    send_payment_status]

        # Shows the current use information
        def me
          render json: @user.sanitized, status: :ok
        end

        # TODO: remove this method
        def send_payment_status
          user = ::User.find(params[:id])
          user.send_payment_status
          render json: user, status: :ok
        end

        def return_subscribed_info
          token = params[:token]
          render json: SubscribedUser.find_by_token(token), status: :ok
        end

        def subscribe
          user = SubscribedUser.create!(
            first_name: params[:first_name],
            last_name: params[:last_name],
            email: params[:email],
            phone_number: params[:phone_number]
          )
          user.send_confirmation

          render json: { status: 'Created' }, status: :created
        end

        def log_out
          @user.invalidate_session!
          render json: { status: 'Invalidated' }, status: :ok
        end

        def create_dealer
          dealer = ::Dealer.create!(
            name: params[:name],
            latitude: params[:latitude],
            longitude: params[:longitude],
            phone_number: params[:phone_number],
            country: params[:country],
            city: params[:city],
            address1: params[:address1],
            address2: params[:address2],
            user: @user
          )

          render json: dealer, status: :created
        end

        def update_dealer
          @user.dealer.update!(params.permit(
                                 :name,
                                 :latitude,
                                 :longitude,
                                 :phone_number,
                                 :country,
                                 :city,
                                 :address1,
                                 :address2
                               ))
          render json: @user.dealer, status: :ok
        end

        def retrieve_dealer
          render json: Dealer.find_by(user: @user), status: :ok
        end

        # TODO: Allow the user to remove a dealer
        def remove_dealer; end

        def verify_availability
          render json: { available: ::User.where(email: params[:email]).size <= 0 }, status: :ok
        end

        def is_phone_verified?
          phone_sections = @user.phone_number.split '-'
          country_code = phone_sections[0]
          phone_number = phone_sections[1]
          token = params[:token]

          if !phone_number || !country_code || !token
            render(json: { err: 'Missing fields' },
                   status: :bad_request) && return
          end

          response = Authy::PhoneVerification.check(
            verification_code: token,
            country_code: country_code,
            phone_number: phone_number
          )

          unless response.ok?
            @user.phone_number_validated = false
            render(json: { err: 'Verify Token Error' },
                   status: :bad_request) && return
          end

          @user.phone_number_validated = true
          @user.save!
          render json: response, status: :ok
        end

        def set_2fa
          @user.require_2fa = true
          @user.save!
          render json: @user, status: :ok
        end

        def send_phone_verification
          phone_sections = @user.phone_number.split '-'
          country_code = phone_sections[0]
          phone_number = phone_sections[1]
          via = params[:via]

          if !phone_number || !country_code || !via
            render(json: { err: 'Missing fields', phone_sections: phone_sections },
                   status: :bad_request) && return
          end

          response = Authy::PhoneVerification.start(
            via: via,
            country_code: country_code,
            phone_number: phone_number
          )

          unless response.ok?
            render(json: { err: 'Error delivering code verification' },
                   status: :bad_request) && return
          end

          render json: response, status: :ok
        end

        def modify_user
          @user.update(permitted_user_params)
          @user.verified = false
          @user.save!
          render json: @user.sanitized, status: :ok
        end

        def modify_address
          @user.update(permitted_address_params)
          @user.verified = false
          @user.save!
          render json: @user.sanitized, status: :ok
        end

        def change_password
          user = ::User.find_by(email: params[:email])
          if user
            token = generate_secure_token
            user.reset_password_token = token
            user.reset_password_sent_at = DateTime.now
            user.save!
            ::Mailers::MailerDevise.new.password_change(
              user.email,
              token,
              params[:callback]
            )
            render json: { status: 'sent' }, status: :ok
          else
            render json: { status: 'failed' }, status: :ok
          end
        end

        def modify_password
          user = ::User.find_by(
            email: params[:email],
            reset_password_token: params[:token]
          )
          if user
            user.reset_password_token = nil
            user.password = params['password']
            user.save!
            render json: { status: 'success' }, status: :ok
          else
            render json: {
              status: 'failed',
              reason: 'Token doesn\'t map to user'
            }, status: :ok
          end
        end

        private

        def permitted_user_params
          params.require(:user).permit(
            :first_name,
            :last_name,
            :phone_number
          )
        end

        def permitted_address_params
          params.require(:address).permit(
            :country,
            :city,
            :primary_address,
            :secondary_address,
            :zip_code
          )
        end

        protected

        def generate_secure_token
          SecureRandom.base58(48)
        end
      end
    end
  end
end
