module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      user = env["warden"]&.user
      reject_unauthorized_connection unless user&.active_for_authentication?
      self.current_user = user
    end
  end
end
