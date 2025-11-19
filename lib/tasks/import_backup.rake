namespace :db do
  desc "Import data from backup SQL file"
  task import_backup: :environment do
    backup_file = Rails.root.join("db/backup/backup-maria.sql")

    unless File.exist?(backup_file)
      puts "❌ Backup file not found: #{backup_file}"
      exit 1
    end

    puts "📂 Importing data from #{backup_file}"
    puts "⚠️  This will clear existing data. Press Ctrl+C to cancel or Enter to continue..."
    STDIN.gets

    ActiveRecord::Base.transaction do
      # Clear existing data in reverse dependency order
      puts "\n🗑️  Clearing existing data..."
      HikeHistory.delete_all
      HikePath.delete_all
      Hike.delete_all
      Session.delete_all
      User.delete_all

      # Reset auto-increment
      ActiveRecord::Base.connection.execute("ALTER TABLE users AUTO_INCREMENT = 1")
      ActiveRecord::Base.connection.execute("ALTER TABLE hikes AUTO_INCREMENT = 1")
      ActiveRecord::Base.connection.execute("ALTER TABLE hike_paths AUTO_INCREMENT = 1")
      ActiveRecord::Base.connection.execute("ALTER TABLE hike_histories AUTO_INCREMENT = 1")

      puts "✅ Existing data cleared\n"

      # Parse backup file
      puts "📖 Parsing backup file..."
      sql_content = File.read(backup_file)

      # Extract and import data for each table
      import_hikes(sql_content)
      import_hike_paths(sql_content)
      member_to_user_map = import_members_as_users(sql_content)
      import_hike_histories(sql_content, member_to_user_map)

      puts "\n✅ Import completed successfully!"
      puts "\n📊 Summary:"
      puts "   Users: #{User.count}"
      puts "   Hikes: #{Hike.count}"
      puts "   Hike Paths: #{HikePath.count}"
      puts "   Hike Histories: #{HikeHistory.count}"
    end
  rescue => e
    puts "\n❌ Import failed: #{e.message}"
    puts e.backtrace.first(5)
    raise ActiveRecord::Rollback
  end

  private

  def import_hikes(sql_content)
    puts "\n📥 Importing hikes..."

    # Extract INSERT statement
    insert_match = sql_content.match(/INSERT INTO `hikes` VALUES\s+(.*?);/m)
    return unless insert_match

    # Use direct SQL import with temporary table
    conn = ActiveRecord::Base.connection

    # Create temporary table with old schema
    conn.execute(<<~SQL)
      CREATE TEMPORARY TABLE temp_hikes (
        id BIGINT PRIMARY KEY,
        number INT,
        day INT,
        difficulty INT,
        starting_point VARCHAR(255),
        trail_name VARCHAR(255),
        carpooling_cost FLOAT,
        distance_km FLOAT,
        elevation_gain FLOAT,
        openrunner_ref VARCHAR(255),
        created_at DATETIME(6),
        updated_at DATETIME(6),
        elevation_loss INT,
        altitude_min INT,
        altitude_max INT,
        updating TINYINT(1),
        last_update_attempt DATETIME(6)
      )
    SQL

    # Insert data into temp table
    conn.execute("INSERT INTO temp_hikes VALUES #{insert_match[1]}")

    # Copy to final table
    conn.execute(<<~SQL)
      INSERT INTO hikes
      SELECT * FROM temp_hikes
    SQL

    count = conn.select_value("SELECT COUNT(*) FROM temp_hikes")
    conn.execute("DROP TEMPORARY TABLE temp_hikes")

    puts "   ✅ Imported #{count} hikes"
  end

  def import_hike_paths(sql_content)
    puts "\n📥 Importing hike paths..."

    insert_match = sql_content.match(/INSERT INTO `hike_paths` VALUES\s+(.*?);/m)
    return unless insert_match

    conn = ActiveRecord::Base.connection

    conn.execute(<<~SQL)
      CREATE TEMPORARY TABLE temp_hike_paths (
        id BIGINT PRIMARY KEY,
        hike_id INT,
        coordinates TEXT,
        created_at DATETIME(6),
        updated_at DATETIME(6)
      )
    SQL

    conn.execute("INSERT INTO temp_hike_paths VALUES #{insert_match[1]}")

    conn.execute(<<~SQL)
      INSERT INTO hike_paths
      SELECT * FROM temp_hike_paths
    SQL

    count = conn.select_value("SELECT COUNT(*) FROM temp_hike_paths")
    conn.execute("DROP TEMPORARY TABLE temp_hike_paths")

    puts "   ✅ Imported #{count} hike paths"
  end

  def import_members_as_users(sql_content)
    puts "\n📥 Importing members as users..."

    roles_match = sql_content.match(/INSERT INTO `roles` VALUES\s+(.*?);/m)
    members_match = sql_content.match(/INSERT INTO `members` VALUES\s+(.*?);/m)

    return {} unless members_match

    conn = ActiveRecord::Base.connection

    # Create temp roles table
    if roles_match
      conn.execute(<<~SQL)
        CREATE TEMPORARY TABLE temp_roles (
          id BIGINT PRIMARY KEY,
          name VARCHAR(255),
          created_at DATETIME(6),
          updated_at DATETIME(6)
        )
      SQL

      conn.execute("INSERT INTO temp_roles VALUES #{roles_match[1]}")
    end

    # Create temp members table
    conn.execute(<<~SQL)
      CREATE TEMPORARY TABLE temp_members (
        id BIGINT PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255),
        phone VARCHAR(255),
        role_id INT,
        created_at DATETIME(6),
        updated_at DATETIME(6)
      )
    SQL

    conn.execute("INSERT INTO temp_members VALUES #{members_match[1]}")

    # Import members as users with role mapping and deduplicate emails
    conn.execute(<<~SQL)
      INSERT INTO users (id, name, email_address, password_digest, role, created_at, updated_at, provider, uid)
      SELECT
        m.id,
        m.name,
        CASE
          WHEN m.email IS NULL OR m.email = ''
          THEN CONCAT('member_', m.id, '@progit.local')
          WHEN (SELECT COUNT(*) FROM temp_members m2 WHERE m2.email = m.email AND m2.id < m.id) > 0
          THEN CONCAT(SUBSTRING_INDEX(m.email, '@', 1), '_', m.id, '@', SUBSTRING_INDEX(m.email, '@', -1))
          ELSE m.email
        END,
        NULL,
        CASE
          WHEN r.name = 'guide' THEN 1
          ELSE 0
        END,
        m.created_at,
        m.updated_at,
        NULL,
        NULL
      FROM temp_members m
      LEFT JOIN temp_roles r ON m.role_id = r.id
    SQL

    count = conn.select_value("SELECT COUNT(*) FROM temp_members")

    # Build member_id to user_id map
    member_to_user_map = {}
    conn.select_all("SELECT id FROM temp_members").each do |row|
      member_to_user_map[row["id"]] = row["id"]
    end

    conn.execute("DROP TEMPORARY TABLE temp_members")
    conn.execute("DROP TEMPORARY TABLE temp_roles") if roles_match

    puts "   ✅ Imported #{count} members as users"
    puts "   ℹ️  Legacy users have no password - they must use 'Forgot password' to set one"

    member_to_user_map
  end

  def import_hike_histories(sql_content, member_to_user_map)
    puts "\n📥 Importing hike histories..."

    insert_match = sql_content.match(/INSERT INTO `hike_histories` VALUES\s+(.*?);/m)
    return unless insert_match

    conn = ActiveRecord::Base.connection

    # Create temp table with old schema (member_id)
    conn.execute(<<~SQL)
      CREATE TEMPORARY TABLE temp_hike_histories (
        id BIGINT PRIMARY KEY,
        hiking_date DATE,
        departure_time VARCHAR(255),
        day_type VARCHAR(255),
        carpooling_cost DECIMAL(5,2),
        member_id INT,
        hike_id INT,
        openrunner_ref VARCHAR(255),
        created_at DATETIME(6),
        updated_at DATETIME(6)
      )
    SQL

    conn.execute("INSERT INTO temp_hike_histories VALUES #{insert_match[1]}")

    # Copy to final table, renaming member_id to user_id
    conn.execute(<<~SQL)
      INSERT INTO hike_histories
        (id, hiking_date, departure_time, day_type, carpooling_cost, user_id, hike_id, openrunner_ref, created_at, updated_at)
      SELECT
        id, hiking_date, departure_time, day_type, carpooling_cost,
        member_id, hike_id, openrunner_ref, created_at, updated_at
      FROM temp_hike_histories
      WHERE member_id IN (SELECT id FROM users)
    SQL

    count = conn.select_value("SELECT COUNT(*) FROM temp_hike_histories WHERE member_id IN (SELECT id FROM users)")
    skipped = conn.select_value("SELECT COUNT(*) FROM temp_hike_histories WHERE member_id NOT IN (SELECT id FROM users)")

    conn.execute("DROP TEMPORARY TABLE temp_hike_histories")

    puts "   ✅ Imported #{count} hike histories"
    puts "   ⚠️  Skipped #{skipped} histories with missing users" if skipped.to_i > 0
  end
end
