module Admin
  class UsersController < ApplicationController
    before_action :authorize_admin
    before_action :set_user, only: [ :update_role ]

    def index
      @users = User.all.order(created_at: :desc)
      authorize! :manage, User
    end

    def update_role
      authorize! :manage, User

      if @user.update(role: params[:role])
        redirect_to admin_users_path, notice: "Role updated to #{@user.role.humanize} for #{@user.name}"
      else
        redirect_to admin_users_path, alert: "Failed to update role"
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def authorize_admin
      redirect_to root_path, alert: "Access denied." unless Current.user&.admin?
    end
  end
end
