# frozen_string_literal: true

require "io/console"

namespace :users do
  desc "Définit le même mot de passe pour tous les users (saisie interactive)."
  task set_default_password: :environment do
    users = User.all

    puts "🔑 Reset du mot de passe pour tous les users"
    puts "   Users concernés : #{users.count}"

    if users.empty?
      puts "\n✅ Aucun user à mettre à jour"
      next
    end

    print "\nNouveau mot de passe : "
    password = STDIN.noecho(&:gets)&.chomp
    puts
    print "Confirmer            : "
    confirmation = STDIN.noecho(&:gets)&.chomp
    puts

    if password.blank? || password != confirmation
      puts "\n❌ Mot de passe vide ou non identique — abandon"
      next
    end

    puts "\n⚠️  Entrée pour continuer, Ctrl+C pour annuler..."
    STDIN.gets

    updated = 0
    failed = []

    ActiveRecord::Base.transaction do
      users.find_each do |user|
        user.password = password
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
