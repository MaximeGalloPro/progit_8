# frozen_string_literal: true

# app/jobs/update_hike_from_openrunner_job.rb
require 'capybara'
require 'selenium-webdriver'

# Job responsible for updating hike information by scraping data from OpenRunner.com
# This job performs web scraping using Capybara with headless Chrome to fetch
# current statistics for a given hike, including distance, elevation gain/loss,
# and altitude information.
#
# The job handles network failures gracefully and ensures the hike's update status
# is always maintained, even in case of errors.
#
# @example
#   UpdateHikeFromOpenrunnerJob.perform_later(hike)
#
# @note This job requires Chrome/Chromium and chromedriver to be installed
# @note The job uses headless mode to avoid opening visible browser windows
#
# @attr_reader [Boolean] updating Indicates if the hike is currently being updated
# @attr_reader [DateTime] last_update_attempt Timestamp of the last update attempt
class UpdateHikeFromOpenrunnerJob < ApplicationJob
    queue_as :default

    SCRAPING_CONFIG = {
        'Distance' => { key: :distance_km, transform: ->(val) { val.tr(',', '.').to_f } },
        'Dénivelé +' => { key: :elevation_gain, transform: ->(val) { val.to_i } },
        'Dénivelé -' => { key: :elevation_loss, transform: ->(val) { val.to_i } },
        'Altitude min.' => { key: :altitude_min, transform: ->(val) { val.to_i } },
        'Altitude max.' => { key: :altitude_max, transform: ->(val) { val.to_i } }
    }.freeze

    def perform(hike)
        setup_capybara
        browser = Capybara::Session.new(:selenium_headless)
        hike.update(updating: true)

        begin
            Rails.logger.info { "🔗 Starting update for hike: #{hike.trail_name}" }
            fetch_and_update_hike_data(browser, hike)
        rescue StandardError => e
            handle_error(e, hike)
            raise e
        ensure
            cleanup(browser)
        end
    end

    private

    def setup_capybara
        Capybara.default_driver = :selenium_headless
        Capybara.javascript_driver = :selenium_headless
        Capybara.app_host = 'https://www.openrunner.com'
    end

    def fetch_and_update_hike_data(browser, hike)
        browser.visit("https://www.openrunner.com/route-details/#{hike.openrunner_ref}")
        sleep 5 # Allow page to load

        updates = collect_hike_updates(browser)
        apply_updates(hike, updates)
    end

    def collect_hike_updates(browser)
        SCRAPING_CONFIG.each_with_object({}) do |(label, config), updates|
            element = browser.find('.or-parcours-info-block', text: label)
            value = element.find('.or-parcours-info-text').text
            updates[config[:key]] = config[:transform].call(value)
        rescue Capybara::ElementNotFound => e
            Rails.logger.warn { "⚠️ Failed to find element '#{label}': #{e.message}" }
        end
    end

    def apply_updates(hike, updates)
        if updates.any?
            updates[:last_update_attempt] = Time.current
            updates[:updating] = false
            hike.update(updates)
            Rails.logger.info { "✅ Successfully updated hike with: #{updates}" }
        else
            hike.update(updating: false, last_update_attempt: Time.current)
            Rails.logger.warn '⚠️ No data found during update'
        end
    end

    def handle_error(error, hike)
        Rails.logger.error { "❌ Error updating hike: #{error.message}" }
        hike.update(updating: false, last_update_attempt: Time.current)
    end

    def cleanup(browser)
        browser.quit
    rescue StandardError => e
        Rails.logger.error { "Failed to cleanup browser session: #{e.message}" }
    end
end
