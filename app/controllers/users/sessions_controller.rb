class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  after_action :after_login, only: :create
  before_action :before_logout, only: :destroy

  protected

  def after_login
    Visit.create(user_id: current_user.id, sign_in_ip: request.remote_ip)

    # if current_user.disabled?
    #   sign_out current_user
    #   flash[:error] = "Your account has been disabled. Please contact an administrator."
    # end
  end

  def before_logout
    visit = current_user.visits.where(signed_out_at: nil)
    visit&.update(signed_out_at: DateTime.current)
  end

  private

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
