class PasswordsController < ApplicationController
  allow_unauthenticated_access
  skip_authorization_check
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: t("flash.passwords.instructions_sent")
  end

  def edit
  end

  def update
    password_attributes = params.permit(:password, :password_confirmation)

    if password_attributes[:password] != password_attributes[:password_confirmation]
      redirect_to edit_password_path(params[:token]), alert: t("flash.passwords.confirmation_mismatch")
    elsif @user.update(password_attributes)
      redirect_to new_session_path, notice: t("flash.passwords.reset_success")
    else
      redirect_to edit_password_path(params[:token]), alert: t("flash.passwords.invalid_password")
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("flash.passwords.invalid_token")
    end
end
