# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # Guest user (not logged in)

    if user.admin?
      # Admin can do everything
      can :manage, :all
    elsif user.moderator?
      # Moderator can manage users (except delete)
      can :read, User
      can :update, User
      cannot :destroy, User

      # Moderator can manage their own profile
      can :manage, User, id: user.id

      # Moderator can manage all hikes
      can :manage, Hike
      can :manage, HikeHistory
      can :manage, HikePath
    else
      # Regular user can only manage their own profile
      can :read, User, id: user.id
      can :update, User, id: user.id
      can :destroy, User, id: user.id

      # Regular user can read hikes but not modify
      can :manage, Hike
      can :manage, HikeHistory
      can :manage, HikePath
    end
  end
end
