class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create test_email ]
  skip_authorization_check
  rate_limit to: 10, within: 3.minutes, only: :create, name: "login", with: -> { redirect_to new_session_url, alert: "Try again later." }
  rate_limit to: 2, within: 5.minutes, only: :test_email, name: "test_email", with: -> { redirect_to new_session_url, alert: "Veuillez patienter avant de renvoyer un email de test." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      session[:login_method] = "password"
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  def test_email
    EmailTestMailer.delivery_test.deliver_now
    redirect_to new_session_path, notice: "Email de test envoyé à gallo.max13@gmail.com."
  rescue StandardError => error
    @email_test_error = email_test_diagnostic(error)
    Rails.logger.error("Test email delivery failed:\n#{@email_test_error}")
    flash.now[:alert] = "Échec de l'envoi de l'email de test. Le diagnostic détaillé est affiché ci-dessous."
    render :new, status: :unprocessable_entity
  end

  private
    def email_test_diagnostic(error)
      smtp = Rails.application.config.action_mailer.smtp_settings || {}

      [
        "Exception : #{error.class}",
        "Message : #{error.message}",
        "Cause : #{error.cause ? "#{error.cause.class}: #{error.cause.message}" : "aucune"}",
        "SMTP : #{smtp[:address]}:#{smtp[:port]}",
        "Domaine SMTP : #{smtp[:domain]}",
        "Utilisateur SMTP : #{smtp[:user_name]}",
        "Mot de passe SMTP présent : #{smtp[:password].present? ? "oui" : "non"}",
        "Authentification : #{smtp[:authentication]}",
        "STARTTLS : #{smtp[:enable_starttls_auto]}",
        "Expéditeur : #{ENV.fetch("MAILER_FROM", "ProGit <noreply@progit.club>")}",
        "Destinataire : #{EmailTestMailer::RECIPIENT}",
        "Trace :",
        *Array(error.backtrace).first(12)
      ].join("\n")
    end
end
