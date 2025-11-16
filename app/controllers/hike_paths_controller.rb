# frozen_string_literal: true

# Manages hiking path data and route visualizations. Handles the creation and
# display of path coordinates, maintains path history in session, and provides
# validation for path points.
class HikePathsController < ApplicationController
    allow_unauthenticated_access only: [ :show ]

    def show
        @hike_path = HikePath.find_by(id: params[:id])
        handle_missing_path unless @hike_path
    end

    def new
        @hike_path = initialize_hike_path
        session.delete(:last_hike_path)
    end

    def create
        @hike_path = build_hike_path

        if validate_points && save_hike_path
            handle_successful_save
        else
            render :new, status: :unprocessable_entity
        end
    end

    private

    def handle_missing_path
        flash[:alert] = t(".not_found")
        redirect_to hikes_path
    end

    def initialize_hike_path
        if session[:last_hike_path]
            HikePath.new(session[:last_hike_path])
        else
            HikePath.new
        end
    end

    def build_hike_path
        HikePath.new
    end

    def validate_points
        return true if points.present?

        @hike_path.errors.add(:points, t(".points_required"))
        false
    end

    def save_hike_path
        hike = Hike.find_by(id: params[:hike_id])
        @hike_path.assign_attributes(
            coordinates: points,
            hike_id: hike&.id
        )
        @hike_path.save
    end

    def handle_successful_save
        flash[:notice] = t(".success")
        session[:last_hike_path] = @hike_path.attributes
        redirect_back fallback_location: new_hike_path
    end

    def points
        @points ||= params[:points]
    end
end
