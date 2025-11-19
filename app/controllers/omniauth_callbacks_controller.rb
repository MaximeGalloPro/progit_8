class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_oauth2
  allow_unauthenticated_access only: [ :google_oauth2, :failure, :invitation, :complete_registration ]
  skip_authorization_check

  def google_oauth2
    auth = request.env["omniauth.auth"]

    # Check if this is a linking request (user already authenticated wanting to link explicitly)
    if session[:linking_account]
      session_record = Session.find_by(id: cookies.signed[:session_id])
      user = session_record&.user

      if user && user.link_google_account(auth)
        session.delete(:linking_account)
        redirect_to user_path, notice: t("flash.omniauth_callbacks.link_success")
      else
        session.delete(:linking_account)
        redirect_to user_path, alert: t("flash.omniauth_callbacks.link_failure")
      end
    else
      # Normal OAuth login flow (auto-links if email exists)
      # Check if user already exists (login) or is new (registration)
      existing_user = User.find_by(email_address: auth.info.email)

      if existing_user
        # Existing user - allow login and auto-link
        user = User.from_omniauth(auth)
        if user&.persisted?
          start_new_session_for(user)
          session[:login_method] = "google"
          redirect_to user_path, notice: t("flash.omniauth_callbacks.google_success")
        else
          redirect_to new_session_path, alert: t("flash.omniauth_callbacks.sign_in_failure")
        end
      else
        # New user - store OAuth data in session and redirect to invitation code page
        session[:pending_oauth] = {
          provider: auth.provider,
          uid: auth.uid,
          email: auth.info.email,
          name: auth.info.name,
          avatar_url: auth.info.image
        }
        redirect_to oauth_invitation_path
      end
    end
  end

  def invitation
    unless session[:pending_oauth]
      redirect_to new_session_path, alert: t("flash.omniauth_callbacks.no_pending_registration")
      return
    end

    @email = session[:pending_oauth]["email"]
    @name = session[:pending_oauth]["name"]
  end

  def complete_registration
    unless session[:pending_oauth]
      redirect_to new_session_path, alert: t("flash.omniauth_callbacks.no_pending_registration")
      return
    end

    unless params[:invitation_code] == ENV["INVITATION_CODE"]
      @email = session[:pending_oauth]["email"]
      @name = session[:pending_oauth]["name"]
      flash.now[:alert] = t("flash.users.invalid_invitation_code")
      render :invitation, status: :unprocessable_entity
      return
    end

    # Create user from stored OAuth data
    oauth_data = session[:pending_oauth]
    user = User.create(
      email_address: oauth_data["email"],
      name: oauth_data["name"],
      provider: oauth_data["provider"],
      uid: oauth_data["uid"],
      avatar_url: oauth_data["avatar_url"],
      role: :user
    )

    if user.persisted?
      session.delete(:pending_oauth)
      start_new_session_for(user)
      session[:login_method] = "google"
      redirect_to user_path, notice: t("flash.users.account_created")
    else
      @email = oauth_data["email"]
      @name = oauth_data["name"]
      flash.now[:alert] = user.errors.full_messages.join(", ")
      render :invitation, status: :unprocessable_entity
    end
  end

  def failure
    redirect_to new_session_path, alert: t("flash.omniauth_callbacks.auth_failure", message: params[:message])
  end
end
