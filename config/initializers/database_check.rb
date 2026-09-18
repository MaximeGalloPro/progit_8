# frozen_string_literal: true

# Check that all configured databases exist on boot
Rails.application.config.after_initialize do
  # Ne vérifier qu'au démarrage d'un serveur web (`bin/rails server`, via bin/dev en
  # développement et Thruster en production). Les tâches rake bootent aussi l'app, et y
  # lever une exception bloquait deux choses :
  #   - le `db:prepare` de bin/docker-entrypoint, qui est précisément ce qui crée les
  #     bases manquantes — le conteneur ne pouvait donc jamais démarrer ;
  #   - le `assets:precompile` du Dockerfile, qui tourne sans base joignable.
  next unless defined?(Rails::Server)

  missing_databases = []

  ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |config|
    next if config.database.blank?

    begin
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.execute("SELECT 1")
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, Trilogy::BaseError
      missing_databases << { name: config.name, database: config.database }
    end
  end

  ActiveRecord::Base.establish_connection

  next if missing_databases.empty?

  db_list = missing_databases.map { |db| "  - #{db[:name]}: #{db[:database]}" }.join("\n")
  create_commands = missing_databases.map { |db| "    \"CREATE DATABASE IF NOT EXISTS #{db[:database]};\"" }.join(" \\\n")

  message = <<~MSG

    #{"=" * 60}
    ⚠️  MISSING DATABASES DETECTED!
    #{"=" * 60}

    The following databases need to be created:
#{db_list}

    Create them with:
      mysql -h $DATABASE_HOST -P $DATABASE_PORT -u $DATABASE_USERNAME -p -e \\
#{create_commands}

    Then run:
      bin/rails db:migrate

    #{"=" * 60}

  MSG

  puts message
  Rails.logger.error message if Rails.env.production?
  raise "Missing databases: #{missing_databases.map { |db| db[:database] }.join(', ')}"
end
