# frozen_string_literal: true

# Maps a hike to an organisation, allowing organisations to maintain
# their own collection of hiking paths and routes
class HikePath < ApplicationRecord
    belongs_to :hike
end
