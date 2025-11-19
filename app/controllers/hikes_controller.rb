# frozen_string_literal: true

# Manages hiking trails and routes within the application. Handles CRUD operations
# for hikes, OpenRunner integration for trail details, and associated path data.
# Provides search functionality and history tracking for hikes.
class HikesController < ApplicationController
    def index
        @results = fetch_hikes
        @results = sort_hikes_by_date(@results)
    end

    def refresh_from_openrunner
        prepare_hike_for_update
        schedule_openrunner_update
        redirect_back_with_update_notice
    end

    def new
        @hike = Hike.new(difficulty: 3)
        @hike_path = HikePath.new
    end

    def edit
        set_hike_and_path
    end

    def create
        @hike = build_hike
        @hike_path = build_hike_path

        if save_hike_with_path
            redirect_to hikes_path, notice: t(".success")
        else
            render_new_with_errors
        end
    end

    def update
        set_hike_and_path
        prepare_coordinates

        if update_hike_with_path
            redirect_to hikes_path, notice: t(".success")
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def fetch_openrunner_details
        details = OpenrunnerFetchService.fetch_details(params[:openrunner_ref])

        if details[:error]
            render json: { error: details[:error] }, status: :unprocessable_entity
        else
            render json: details
        end
    end

    def check_updating_status
        hike_ids = params[:ids]&.split(",")&.map(&:to_i) || []
        return render json: { updating: [], completed: [] } if hike_ids.empty?

        hikes = Hike.where(id: hike_ids)
        updating = hikes.where(updating: true).pluck(:id)
        completed = hike_ids - updating

        render json: { updating: updating, completed: completed }
    end

    def destroy
        @hike = find_hike
        @hike.destroy
        redirect_to hikes_path, notice: t(".success")
    end

    private

    def sort_hikes_by_date(hikes)
        hikes.sort_by { |hike| hike.last_hiking_date || Date.new(1, 1, 1) }.reverse
    end

    def prepare_hike_for_update
        @hike = find_hike
        @hike.update(updating: true)
    end

    def schedule_openrunner_update
        UpdateHikeFromOpenrunnerJob.perform_later(@hike)
    end

    def redirect_back_with_update_notice
        redirect_back(
            fallback_location: hikes_path,
            **build_redirect_options
        )
    end

    def build_redirect_options
        {
            notice: t(".updating", name: @hike.trail_name),
            search: determine_search_param,
            redirect_path: params[:redirect_path]
        }.compact
    end

    def determine_search_param
        return params[:search] if params[:search].present?
        return nil if params[:redirect_path].present?

        nil
    end

    def set_hike_and_path
        @hike = find_hike
        @hike_path = @hike.hike_path
    end

    def build_hike
        Hike.new(hike_params)
    end

    def build_hike_path
        HikePath.new(coordinates: params[:hike][:coordinates])
    end

    def save_hike_with_path
        return false unless @hike.save

        @hike_path.hike_id = @hike.id
        @hike_path.save
    end

    def render_new_with_errors
        render :new, status: :unprocessable_entity,
                     params: { hike: @hike, coordinates: params[:coordinates] }
    end

    def find_hike
        Hike.find_by(id: params[:id])
    end

    def prepare_coordinates
        return unless params[:hike][:coordinates] == "[]"

        params[:hike][:coordinates] = ""
    end

    def update_hike_with_path
        @hike_path ||= HikePath.new(hike_id: @hike.id)
        @hike.update(hike_params) && @hike_path&.update(coordinates: params[:hike][:coordinates])
    end

    def hike_params
        params_with_converted_distance = params.require(:hike).permit(
            :number,
            :difficulty,
            :starting_point,
            :trail_name,
            :carpooling_cost,
            :distance_km,
            :elevation_gain,
            :elevation_loss,
            :altitude_min,
            :altitude_max,
            :openrunner_ref,
            :day
        )

        convert_distance_format(params_with_converted_distance)
    end

    def convert_distance_format(params)
        params[:distance_km].tr!(",", ".") if params[:distance_km].present?
        params
    end

    def fetch_hikes
        Hike.with_latest_history
            .then { |scope| apply_search(scope) }
            .order_by_latest_date
            .distinct
            .includes(:hike_histories, :hike_path, latest_history: :user)
    end

    def apply_search(scope)
        params[:search].present? ? scope.search_by_term(params[:search]) : scope
    end
end
