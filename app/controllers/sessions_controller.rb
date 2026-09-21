class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  skip_authorization_check
  rate_limit to: 10, within: 3.minutes, only: :create, name: "login", with: -> { redirect_to new_session_url, alert: t("flash.sessions.rate_limited") }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      session[:login_method] = "password"
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("flash.sessions.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
