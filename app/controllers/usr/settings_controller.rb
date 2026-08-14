class Usr::SettingsController < ApplicationController
  def show
  end

  def update
    if current_user.update(settings_params)
      redirect_to usr_settings_path, notice: "Settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :email_notifications_enabled,
      :sms_notifications_enabled,
      :job_alert_notifications_enabled,
      :recommended_role_notifications_enabled,
      :upcoming_job_reminder_notifications_enabled
    )
  end
end
