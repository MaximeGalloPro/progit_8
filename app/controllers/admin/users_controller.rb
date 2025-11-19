module Admin
  class UsersController < ApplicationController
    before_action :authorize_admin_or_moderator
    before_action :set_user, only: [ :edit, :update, :update_role ]
    before_action :prevent_self_edit, only: [ :edit, :update, :update_role ]

    PER_PAGE = 10

    def index
      @page = (params[:page] || 1).to_i
      @total_users = User.count
      @total_pages = (@total_users.to_f / PER_PAGE).ceil
      @users = User.order(created_at: :desc).limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
      authorize! :update, User
    end

    def edit
      authorize! :update, User
    end

    def update
      authorize! :update, User

      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Utilisateur #{@user.name} mis à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def update_role
      authorize! :manage, User

      if @user.update(role: params[:role])
        redirect_to admin_users_path, notice: "Rôle mis à jour : #{@user.role.humanize} pour #{@user.name}"
      else
        redirect_to admin_users_path, alert: "Échec de la mise à jour du rôle"
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def authorize_admin_or_moderator
      unless Current.user&.admin? || Current.user&.moderator?
        redirect_to root_path, alert: "Accès refusé."
      end
    end

    def prevent_self_edit
      if @user.id == Current.user&.id
        redirect_to admin_users_path, alert: "Vous ne pouvez pas modifier votre propre profil via cet écran."
      end
    end

    def user_params
      base_params = params.require(:user).permit(:name, :nickname, :email_address, :phone_number)
      base_params[:role] = params[:user][:role] if Current.user&.admin? && params[:user][:role].present?
      base_params
    end
  end
end
