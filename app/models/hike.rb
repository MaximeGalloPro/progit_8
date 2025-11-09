# frozen_string_literal: true

# Represents a hiking trail with its characteristics, history, and associated statistics.
# Manages trail information, difficulty levels, and hiking events tracking
class Hike < ApplicationRecord
    # Associations
    has_many :hike_histories, dependent: :destroy
    has_one :latest_history,
            -> { order(hiking_date: :desc) },
            class_name: 'HikeHistory',
            foreign_key: :hike_id,
            dependent: :destroy,
            inverse_of: :hike
    has_one :hike_path, dependent: :destroy

    # Callbacks
    before_validation :convert_distance_separator

    # Validations
    validates :difficulty, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
    validates :starting_point, presence: true
    validates :trail_name, presence: true

    # Scopes de base
    scope :ordered_by_trail_name, -> { order(:trail_name) }
    scope :by_difficulty, ->(level) { where(difficulty: level) }

    # Scopes avec latest_history
    scope :with_latest_history, -> { includes(:latest_history) }
    scope :order_by_latest_date, lambda {
        left_joins(:latest_history)
            .order('hike_histories.hiking_date DESC')
    }

    # Scopes temporels
    scope :this_year, lambda {
        joins(:latest_history)
            .where(hike_histories: { hiking_date: Date.current.beginning_of_year.. })
            .distinct
    }

    scope :this_month, lambda {
        joins(:latest_history)
            .where(hike_histories: { hiking_date: Date.current.beginning_of_month.. })
            .distinct
    }

    scope :past_hikes, lambda {
        joins(:latest_history)
            .where(hike_histories: { hiking_date: ...Date.current })
            .order('hike_histories.hiking_date DESC')
    }

    # Scope de recherche
    scope :search_by_term, lambda { |term|
        return all if term.blank?

        normalized_term = term.strip
        date_pattern = normalized_term.match(%r{(\d{1,2})/(\d{4})})

        if date_pattern
            month = date_pattern[1].to_i
            year = date_pattern[2].to_i
            start_date = Date.new(year, month, 1)
            end_date = start_date.end_of_month

            joins(:latest_history)
                .where('hike_histories.hiking_date BETWEEN ? AND ?', start_date, end_date)
        else
            wild_term = "%#{normalized_term}%"
            where(
                "hikes.trail_name LIKE :term OR
        hikes.starting_point LIKE :term OR
        CAST(hikes.number AS CHAR) LIKE :term",
                term: wild_term
            )
        end
    }

    # Scopes statistiques
    scope :with_elevation, -> { where.not(elevation_gain: nil) }
    scope :with_distance, -> { where.not(distance_km: nil) }
    scope :by_difficulty_range, ->(min, max) { where(difficulty: min..max) }

    # Méthodes de classe
    def self.todays_hike
        today_query = joins(:hike_histories)
                      .select('hikes.*, hike_histories.departure_time,
                             hike_histories.hiking_date')

        today_hike = today_query
                     .where(hike_histories: { hiking_date: Date.current })
                     .first

        return today_hike if today_hike.present?

        today_query
            .where('hike_histories.hiking_date > ?', Date.current)
            .order('hike_histories.hiking_date ASC')
            .first
    end

    def self.total_distance
        sum(:distance_km)
    end

    # Méthodes d'instance
    def difficulty_text
        case difficulty
        when 1 then I18n.t('hike.difficulty.very_easy')
        when 2 then I18n.t('hike.difficulty.easy')
        when 3 then I18n.t('hike.difficulty.medium')
        when 4 then I18n.t('hike.difficulty.hard')
        when 5 then I18n.t('hike.difficulty.very_hard')
        else I18n.t('hike.difficulty.undefined')
        end
    end

    def last_hiking_date
        latest_history&.hiking_date
    end

    def last_guide_name
        latest_history&.member&.name
    end

    private

    def convert_distance_separator
        self.distance_km = distance_km.to_s.tr(',', '.') if distance_km.present?
    end
end
