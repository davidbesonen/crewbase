class Usr::NotificationCardComponent < ApplicationComponent
  def initialize(notification:)
    @notification = notification
  end

  private

  attr_reader :notification
end
