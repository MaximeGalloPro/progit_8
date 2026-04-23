# frozen_string_literal: true

namespace :users do
  desc "Supprime les users parasites (bots/spam). Garde les membres legacy (@progit.local) + whitelist."
  task cleanup_parasites: :environment do
    whitelist_emails = [ "gallo.max13@gmail.com" ]

    valid_users = User.where("email_address LIKE ?", "%@progit.local")
                      .or(User.where(email_address: whitelist_emails))
    parasites = User.where.not(id: valid_users)

    puts "🧹 Nettoyage des users parasites"
    puts "   Valides à garder         : #{valid_users.count}"
    puts "   Parasites à supprimer    : #{parasites.count}"
    puts "   Hike histories liées     : #{HikeHistory.where(user_id: parasites).count}"
    puts "   Sessions liées           : #{Session.where(user_id: parasites).count}"

    if parasites.empty?
      puts "\n✅ Aucun parasite à supprimer"
      next
    end

    puts "\n⚠️  Entrée pour continuer, Ctrl+C pour annuler..."
    STDIN.gets

    ActiveRecord::Base.transaction do
      HikeHistory.where(user_id: parasites).delete_all
      Session.where(user_id: parasites).delete_all
      deleted = parasites.delete_all

      puts "\n✅ #{deleted} users parasites supprimés"
      puts "   Users restants           : #{User.count}"
      puts "   Hike histories restantes : #{HikeHistory.count}"
    end
  end
end
