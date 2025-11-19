# frozen_string_literal: true

# Job responsible for updating hike information by scraping data from OpenRunner.com
# Delegates the actual scraping to OpenrunnerFetchService.
#
# @example
#   UpdateHikeFromOpenrunnerJob.perform_later(hike)
class UpdateHikeFromOpenrunnerJob < ApplicationJob
    queue_as :default

    def perform(hike)
        Rails.logger.info { "🔗 Starting update for hike: #{hike.trail_name}" }

        details = OpenrunnerFetchService.fetch_details(hike.openrunner_ref)

        if details[:error]
            handle_error(details[:error], hike)
        else
            apply_updates(hike, details)
        end
    rescue StandardError => e
        handle_error(e.message, hike)
        raise e
    end

    private

    def apply_updates(hike, updates)
        # Préserver le nom utilisateur et ajouter le nom OpenRunner entre parenthèses
        if updates[:trail_name].present? && hike.trail_name.present?
            openrunner_name = updates[:trail_name]
            # Ne pas ajouter si déjà présent ou si c'est le même nom
            unless hike.trail_name.include?("(openrunner:") || hike.trail_name == openrunner_name
                updates[:trail_name] = "#{hike.trail_name} (openrunner: #{openrunner_name})"
            else
                updates.delete(:trail_name) # Garder le nom existant
            end
        end

        updates[:last_update_attempt] = Time.current
        updates[:updating] = false
        hike.update(updates)
        Rails.logger.info { "✅ Successfully updated hike with: #{updates}" }
    end

    def handle_error(error_message, hike)
        Rails.logger.error { "❌ Error updating hike: #{error_message}" }
        hike.update(updating: false, last_update_attempt: Time.current)
    end
end
