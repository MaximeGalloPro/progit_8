class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # CanCanCan authorization - secure by default
  load_and_authorize_resource unless: :skip_authorization?
  check_authorization unless: :skip_authorization?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_path = authenticated? ? hikes_path : root_path
    redirect_to redirect_path, alert: "Vous n'avez pas les permissions nécessaires pour effectuer cette action."
  end

  private

  def skip_authorization?
    controller_name == 'sessions' ||
    controller_name == 'passwords' ||
    controller_name == 'omniauth_callbacks' ||
    controller_name == 'map_test' ||
    controller_path == 'rails/health'
  end

  def current_ability
    @current_ability ||= Ability.new(Current.user)
  end
end
