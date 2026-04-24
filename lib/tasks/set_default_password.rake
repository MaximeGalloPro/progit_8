# frozen_string_literal: true

namespace :users do
  desc "Définit le mot de passe de tous les users à 'progitmazan'."
  task set_default_password: :environment do
    default_password = "progitmazan"
    users = User.all

    puts "🔑 Reset du mot de passe pour tous les users"
    puts "   Users concernés         : #{users.count}"
    puts "   Nouveau mot de passe    : #{default_password}"

    if users.empty?
      puts "\n✅ Aucun user à mettre à jour"
      next
    end

    puts "\n⚠️  Entrée pour continuer, Ctrl+C pour annuler..."
    STDIN.gets

    updated = 0
    failed = []

    ActiveRecord::Base.transaction do
      users.find_each do |user|
        user.password = default_password
        if user.save
          updated += 1
        else
          failed << [ user.id, user.email_address, user.errors.full_messages.join(", ") ]
        end
      end

      if failed.any?
        puts "\n❌ Échec pour #{failed.count} user(s) :"
        failed.each { |id, email, msg| puts "   - ##{id} #{email} → #{msg}" }
        raise ActiveRecord::Rollback
      end
    end

    if failed.any?
      puts "\n⚠️  Transaction annulée — aucun user mis à jour"
    else
      puts "\n✅ #{updated} mots de passe mis à jour"
    end
  end
end
