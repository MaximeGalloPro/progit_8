# frozen_string_literal: true

# Manages hiking history records including creation, updates, and listing of past
# hikes. Tracks hiking dates, guides, and associated metadata for each completed
# hike.
class HikeHistoriesController < ApplicationController
    before_action :set_hikes, only: %i[new edit create update]
    before_action :set_users, only: %i[new edit create update]
    before_action :set_hike_history, only: %i[edit update destroy]

    PER_PAGE = 20

    def index
        @hike = Hike.find_by(id: params[:hike_id]) if params[:hike_id].present?
        @page = (params[:page] || 1).to_i

        base_query = fetch_hike_histories_base
        @total_count = base_query.count
        @total_pages = (@total_count.to_f / PER_PAGE).ceil
        @results = base_query.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    end

    def new
        @hike_history = HikeHistory.new
    end

    def edit; end

    def create
        @hike_history = HikeHistory.new(hike_history_params)

        if @hike_history.save
            redirect_to hikes_path, notice: t(".success")
        else
            handle_create_error
        end
    rescue ActionController::ParameterMissing
        handle_invalid_parameters
    end

    def update
        if @hike_history.update(hike_history_params)
            redirect_to hikes_path, notice: t(".success")
        else
            handle_update_error
        end
    rescue ActionController::ParameterMissing
        flash.now[:alert] = t(".invalid_params")
        render :edit, status: :unprocessable_entity
    end

    def destroy
        @hike_history.destroy
        redirect_to hikes_path, notice: t(".success")
    end

    private

    def set_hikes
        @hikes = Hike.order(:trail_name)
    end

    def set_users
        @users = User.order(:name)
    end

    def set_hike_history
        @hike_history = HikeHistory.find_by(id: params[:id])
    end

    def fetch_hike_histories_base
        histories = HikeHistory.includes(:hike, :user).order(hiking_date: :desc)
        histories = histories.where(hike_id: params[:hike_id]) if params[:hike_id].present?
        histories
    end

    def handle_create_error
        flash.now[:alert] = t(".validation_error")
        render :new, status: :unprocessable_entity
    end

    def handle_update_error
        flash.now[:alert] = t(".validation_error")
        render :edit, status: :unprocessable_entity
    end

    def handle_invalid_parameters
        flash.now[:alert] = t(".invalid_params")
        @hike_history = HikeHistory.new
        render :new, status: :unprocessable_entity
    end

    def hike_history_params
        params.require(:hike_history).permit(
            :hiking_date,
            :departure_time,
            :day_type,
            :carpooling_cost,
            :hike_id,
            :user_id,
            :openrunner_ref,
        )
    end
end
