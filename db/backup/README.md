# Import des données depuis l'ancienne version

## Différences entre backup et structure actuelle

### Tables supprimées
- **`guides`** - Supprimée complètement
- **`roles`** - Remplacée par un enum dans `users.role`

### Tables renommées
- **`members`** → **`users`**
  - `email` → `email_address` (obligatoire)
  - `role_id` → `role` (enum: 0=user, 1=moderator, 2=admin)
  - Ajout: `password_digest`, `provider`, `uid`, `nickname`, `avatar_url`
  - Suppression: `phone`

### Tables modifiées
- **`hike_histories`**: `member_id` → `user_id`

### Tables identiques
- **`hikes`** - ✅ Aucun changement
- **`hike_paths`** - ✅ Aucun changement

### Tables ajoutées
- **`sessions`** - Nouvelle table pour Rails 8 auth

## Utilisation du script d'import

### 1. Prérequis
- Le fichier de backup doit être dans `db/backup/backup-maria.sql`
- La base de données doit être créée et migrée
- Docker doit être lancé

### 2. Lancer l'import

```bash
make bash
bundle exec rails db:import_backup
```

Ou directement :

```bash
docker compose exec web bash -c "bundle exec rails db:import_backup"
```

### 3. Confirmation

Le script vous demandera de confirmer avant de supprimer les données existantes.
Appuyez sur **Enter** pour continuer ou **Ctrl+C** pour annuler.

## Gestion des cas particuliers

### Emails en double
Si plusieurs membres ont le même email, le script ajoute automatiquement l'ID du membre à l'email des doublons :
- Premier membre : `email@example.com`
- Deuxième membre : `email_42@example.com`

### Emails manquants
Les membres sans email reçoivent un email généré :
- Format : `member_{ID}@progit.local`
- Exemple : `member_123@progit.local`

### Mapping des rôles
- `guide` (ancien role_id=1) → `moderator` (role=1)
- `membre` (ancien role_id=2) → `user` (role=0)

### Utilisateurs sans mot de passe
Tous les utilisateurs importés n'ont **pas de mot de passe**.
Ils doivent utiliser la fonctionnalité "Mot de passe oublié" pour créer leur premier mot de passe.

### Hike histories orphelines
Les `hike_histories` liées à des `member_id` inexistants sont automatiquement ignorées.
Le script affiche le nombre d'entrées ignorées.

## Résultat de l'import

L'import affiche un résumé :

```
✅ Import completed successfully!

📊 Summary:
   Users: 400
   Hikes: 423
   Hike Paths: 108
   Hike Histories: 497
```

### Vérifications post-import

```bash
# Compter les utilisateurs par rôle
rails runner 'User.group(:role).count'

# Compter les utilisateurs sans mot de passe
rails runner 'User.where(password_digest: nil).count'

# Vérifier les emails en double
rails runner 'User.select(:email_address).group(:email_address).having("COUNT(*) > 1").count'
```

## Rollback

Si l'import échoue, la transaction est annulée automatiquement (rollback).
Aucune donnée ne sera modifiée en cas d'erreur.

## Notes techniques

- Le script utilise des tables temporaires pour importer les données
- L'import se fait dans une transaction unique
- Les IDs originaux sont conservés pour maintenir les relations
- Le charset est conservé (utf8mb4_unicode_ci)
