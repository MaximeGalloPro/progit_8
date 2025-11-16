# frozen_string_literal: true

# app/services/openrunner_fetch_service.rb
require "capybara"
require "selenium-webdriver"

# Service to fetch hiking trail details from Openrunner.com
# This service uses Capybara with headless Selenium to scrape trail information
# including distance, elevation, and route details.
class OpenrunnerFetchService
    TECHNICAL_ELEMENTS = {
        distance_km: [ "Distance", :to_f ],
        elevation_gain: [ "Dénivelé +", :to_i ],
        elevation_loss: [ "Dénivelé -", :to_i ],
        altitude_min: [ "Altitude min.", :to_i ],
        altitude_max: [ "Altitude max.", :to_i ]
    }.freeze

    def self.fetch_details(openrunner_ref)
        Rails.logger.debug { "\n🚀 Starting OpenrunnerFetchService for ref: #{openrunner_ref}" }
        new(openrunner_ref).fetch_details
    end

    def initialize(openrunner_ref)
        @openrunner_ref = openrunner_ref
        @url = "https://www.openrunner.com/route-details/#{openrunner_ref}"
        Rails.logger.debug { "📌 Initialized with URL: #{@url}" }
    end

    def fetch_details
        setup_browser
        result = fetch_data
        Rails.logger.debug { "📊 Retrieved data: #{result.inspect}" }
        result
    rescue StandardError => e
        handle_error(e)
    ensure
        cleanup_browser
    end

    private

    def setup_browser
        Rails.logger.debug "\n🔧 Setting up Capybara..."
        configure_capybara
        create_browser_session
        Rails.logger.debug "✅ Capybara setup completed"
    end

    def configure_capybara
        Capybara.register_driver :selenium_remote do |app|
            options = Selenium::WebDriver::Chrome::Options.new
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
            options.add_argument("--window-size=1920,1080")

            Capybara::Selenium::Driver.new(
                app,
                browser: :remote,
                url: ENV.fetch("SELENIUM_REMOTE_URL", "http://selenium:4444"),
                options: options
            )
        end

        Capybara.default_driver = :selenium_remote
        Capybara.javascript_driver = :selenium_remote
        Capybara.app_host = "https://www.openrunner.com"
    end

    def create_browser_session
        Rails.logger.debug "🌐 Creating new browser session..."
        @browser = Capybara::Session.new(:selenium_remote)
    end

    def fetch_data
        load_page
        collect_trail_data
    end

    def load_page
        Rails.logger.debug { "\n🌐 Visiting URL: #{@url}" }
        @browser.visit(@url)
        Rails.logger.debug "⏳ Waiting 5 seconds for page load..."
        sleep 5
        Rails.logger.debug "✅ Page loaded"
    end

    def collect_trail_data
        {}.tap do |result|
            result.merge!(fetch_trail_name)
            result.merge!(fetch_starting_point)
            result.merge!(fetch_technical_elements)
        end.compact
    end

    def fetch_trail_name
        Rails.logger.debug "\n🔍 Fetching trail name..."
        { trail_name: @browser.find("h1.text-route-detail-header").text.strip }
    rescue Capybara::ElementNotFound => e
        Rails.logger.debug { "⚠️ Could not find trail name: #{e.message}" }
        {}
    end

    def fetch_starting_point
        Rails.logger.debug "\n🔍 Fetching starting point..."
        location_element = @browser.all(".text-nav.font-semibold span.truncate").first
        return {} unless location_element

        { starting_point: location_element.text.strip }
    rescue Capybara::ElementNotFound => e
        Rails.logger.debug { "⚠️ Could not find starting point: #{e.message}" }
        {}
    end

    def fetch_technical_elements
        Rails.logger.debug "\n🔍 Starting to fetch technical elements..."
        TECHNICAL_ELEMENTS.each_with_object({}) do |(key, (text, conversion)), result|
            value = fetch_single_element(text, conversion)
            result[key] = value if value
        end
    end

    def fetch_single_element(text, conversion_method)
        element = @browser.find(".or-parcours-info-block", text: text)
        value_element = element.find(".or-parcours-info-text")
        process_element_value(value_element.text, conversion_method)
    rescue Capybara::ElementNotFound => e
        log_element_error(text, e)
        nil
    end

    def process_element_value(raw_value, conversion_method)
        cleaned_value = raw_value.tr(",", ".")
        cleaned_value.send(conversion_method)
    end

    def handle_error(error)
        Rails.logger.debug do
            "❌ Error: #{error.class}\n#{error.message}\n#{error.backtrace.join("\n")}"
        end
        { error: error.message }
    end

    def cleanup_browser
        return unless @browser

        Rails.logger.debug "🧹 Cleaning up browser session..."
        @browser.quit
        Rails.logger.debug "👋 Browser session closed"
    end

    def log_element_error(element_name, error)
        Rails.logger.debug { "⚠️ Could not find #{element_name}: #{error.message}" }
    end
end
