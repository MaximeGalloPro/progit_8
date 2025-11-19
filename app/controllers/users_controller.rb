class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  skip_load_and_authorize_resource
  skip_authorization_check

  before_action :set_user, except: [ :new, :create, :create_guide ]
  before_action :authorize_user, except: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(signup_params)
    @user.role = :user # Default role

    if @user.save
      start_new_session_for(@user)
      session[:login_method] = "password"
      redirect_to stats_dashboard_path, notice: t("flash.users.account_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to user_path, notice: t("flash.users.profile_updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    reset_authentication
    redirect_to root_path, notice: t("flash.users.account_deleted")
  end

  def link_google
    session[:linking_account] = true
    redirect_to "/auth/google_oauth2", allow_other_host: true
  end

  def unlink_google
    unless @user.password_digest.present?
      redirect_to user_path, alert: t("flash.users.set_password_first") and return
    end

    # Check if user logged in with Google
    logged_in_with_google = session[:login_method] == "google"

    if @user.unlink_google_account
      if logged_in_with_google
        # User logged in with Google, need to logout after unlinking
        reset_authentication
        redirect_to root_path, notice: t("flash.users.google_unlinked_logout")
      else
        # User logged in with password, can stay logged in
        redirect_to user_path, notice: t("flash.users.google_unlinked")
      end
    else
      redirect_to user_path, alert: t("flash.users.unlink_failure")
    end
  end

  def create_guide
    guide = User.new(guide_params)
    guide.role = :user # Default role
    guide.password = SecureRandom.alphanumeric(16) # Temporary password

    if guide.save
      # TODO: Send email to guide with password reset link
      render json: { success: true, guide: { id: guide.id, email: guide.email_address, name: guide.name } }
    else
      render json: { success: false, errors: guide.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
    redirect_to root_path, alert: t("flash.users.must_be_signed_in") unless @user
  end

  def authorize_user
    action = case action_name
    when "show" then :read
    when "update", "link_google", "unlink_google" then :update
    when "destroy" then :destroy
    when "create_guide" then :create
    end

    if action_name == "create_guide"
      # For create_guide, authorize against the User class
      authorize! action, User
    elsif action
      # For other actions, authorize against the current user instance
      authorize! action, @user
    end
  end

  def signup_params
    params.require(:user).permit(:email_address, :name, :password)
  end

  def user_params
    params.require(:user).permit(:nickname, :phone_number, :password)
  end

  def guide_params
    params.require(:guide).permit(:email_address, :name, :nickname)
  end
end
