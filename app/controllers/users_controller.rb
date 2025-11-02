class UsersController < ApplicationController
  before_action :set_user
  before_action :authorize_user

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to user_path, notice: "Profile updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    reset_authentication
    redirect_to root_path, notice: "Your account has been deleted."
  end

  def link_google
    session[:linking_account] = true
    redirect_to "/auth/google_oauth2", allow_other_host: true
  end

  def unlink_google
    unless @user.password_digest.present?
      redirect_to user_path, alert: "You must set a password before unlinking your Google account." and return
    end

    # Check if user logged in with Google
    logged_in_with_google = session[:login_method] == "google"

    if @user.unlink_google_account
      if logged_in_with_google
        # User logged in with Google, need to logout after unlinking
        reset_authentication
        redirect_to root_path, notice: "Google account unlinked. Please sign in with your password."
      else
        # User logged in with password, can stay logged in
        redirect_to user_path, notice: "Google account unlinked successfully."
      end
    else
      redirect_to user_path, alert: "Failed to unlink Google account."
    end
  end

  private

  def set_user
    @user = Current.user
    redirect_to root_path, alert: "You must be signed in." unless @user
  end

  def authorize_user
    action = case action_name
             when "show" then :read
             when "update", "link_google", "unlink_google" then :update
             when "destroy" then :destroy
             end
    authorize! action, @user if action
  end

  def user_params
    params.require(:user).permit(:nickname, :password)
  end
end
