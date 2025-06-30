# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :device_identifier

    def connect
      self.device_identifier = request.params[:hash]
      self.current_user = find_verified_user
    end

    private

    def find_verified_user # this checks whether a user is authenticated with devise
      verified_user = User.find_by(id: cookies.signed['user.id'])
      if verified_user && cookies.signed['user.expires_at'] > Time.now
        return verified_user
      #else
        #reject_unauthorized_connection unless self.device_identifier.present?
      end
      nil
    end
  end
end
