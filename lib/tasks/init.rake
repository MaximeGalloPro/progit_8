namespace :app do
  desc "Initialize the project with default admin user"
  task init: :environment do
    if User.exists?(email_address: "admin@example.com")
      puts "Admin user already exists!"
    else
      User.create!(
        name: "Admin User",
        email_address: "admin@example.com",
        password: "password123",
        role: :admin
      )
      puts "✓ Admin user created successfully!"
      puts "  Email: admin@example.com"
      puts "  Password: password123"
    end

    unless User.exists?(email_address: "user@example.com")
      User.create!(
        name: "Test User",
        email_address: "user@example.com",
        password: "password123",
        role: :user
      )
      puts "✓ Test user created successfully!"
      puts "  Email: user@example.com"
      puts "  Password: password123"
    end

    unless User.exists?(email_address: "moderator@example.com")
      User.create!(
        name: "Moderator User",
        email_address: "moderator@example.com",
        password: "password123",
        role: :moderator
      )
      puts "✓ Moderator user created successfully!"
      puts "  Email: moderator@example.com"
      puts "  Password: password123"
    end
  end
end
