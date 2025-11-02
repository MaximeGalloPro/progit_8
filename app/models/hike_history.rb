# frozen_string_literal: true

# Tracks individual hike participations, recording details such as dates,
# times, costs, and references for each member's hiking activity
class HikeHistory < ApplicationRecord
    belongs_to :hike

    # Validations de présence pour tous les champs requis
    validates :hiking_date, presence: true
    validates :departure_time, presence: true

    # Validations numériques avec contraintes spécifiques
    validates :carpooling_cost,
              numericality: { greater_than_or_equal_to: 0 },
              allow_blank: true
    validates :openrunner_ref,
              numericality: { only_integer: true },
              allow_blank: true
end
