class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_oauth2
  allow_unauthenticated_access only: [:google_oauth2, :failure]
  skip_authorization_check

  def google_oauth2
    auth = request.env["omniauth.auth"]

    # Check if this is a linking request (user already authenticated wanting to link explicitly)
    if session[:linking_account]
      session_record = Session.find_by(id: cookies.signed[:session_id])
      user = session_record&.user

      if user && user.link_google_account(auth)
        session.delete(:linking_account)
        redirect_to user_path, notice: t('flash.omniauth_callbacks.link_success')
      else
        session.delete(:linking_account)
        redirect_to user_path, alert: t('flash.omniauth_callbacks.link_failure')
      end
    else
      # Normal OAuth login flow (auto-links if email exists)
      user = User.from_omniauth(auth)

      if user&.persisted?
        start_new_session_for(user)
        session[:login_method] = "google"
        redirect_to user_path, notice: t('flash.omniauth_callbacks.google_success')
      else
        redirect_to new_session_path, alert: t('flash.omniauth_callbacks.sign_in_failure')
      end
    end
  end

  def failure
    redirect_to new_session_path, alert: t('flash.omniauth_callbacks.auth_failure', message: params[:message])
  end
end
