# frozen_string_literal: true

# Tracks individual hike participations, recording details such as dates,
# times, costs, and references for each member's hiking activity
class HikeHistory < ApplicationRecord
    belongs_to :hike
    belongs_to :user

    # Validations de présence pour tous les champs requis
    validates :hiking_date, presence: true
    validates :departure_time, presence: true
    validates :user_id, presence: true

    # Validation d'unicité pour éviter deux randonnées du même parcours le même jour
    validates :hike_id, uniqueness: {
      scope: :hiking_date,
      message: "Cette randonnée est déjà programmée pour cette date"
    }

    # Validations numériques avec contraintes spécifiques
    validates :carpooling_cost,
              numericality: { greater_than_or_equal_to: 0 },
              allow_blank: true
    validates :openrunner_ref,
              numericality: { only_integer: true },
              allow_blank: true
end
