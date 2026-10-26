class Usr::NotificationsController < ApplicationController
  def index
    notifications = current_user.notifications
      .includes(:actor, :notifiable)
      .recent_first
      .to_a
    @unread_notifications, @read_notifications = notifications.partition(&:unread?)
  end

  def read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!
    redirect_to usr_notifications_path
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to usr_notifications_path, notice: "All notifications marked as read."
  end

  def clear_read
    current_user.notifications.read.delete_all
    redirect_to usr_notifications_path, notice: "Read notifications cleared."
  end
end
