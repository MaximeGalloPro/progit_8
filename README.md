# ProGit 8

Application Rails 8.1.1 de gestion de randonnées avec authentification, autorisation par rôles, et tableau de bord statistiques.

## Vue d'ensemble

ProGit 8 est une application web permettant de :
- Gérer des randonnées (création, modification, suppression)
- Suivre l'historique des randonnées effectuées
- Visualiser des statistiques et graphiques
- Gérer des utilisateurs avec différents rôles (utilisateur, modérateur, administrateur)
- S'authentifier via email/mot de passe ou Google OAuth2
- Visualiser les parcours de randonnées sur carte

## Stack technique

- **Framework** : Ruby on Rails 8.1.1
- **Base de données** : MariaDB (via adapter Trilogy)
- **Authentification** : Rails 8 Authentication + Google OAuth2
- **Autorisation** : CanCanCanCan
- **Frontend** : Tailwind CSS v4 (thème sombre)
- **JavaScript** : Importmap, Stimulus
- **Charts** : Chart.js
- **Conteneurisation** : Docker + Docker Compose
- **Internationalisation** : I18n (Français)

## Démarrage rapide

### Prérequis

- Docker
- Docker Compose V2
- Make

### Installation

1. **Cloner le dépôt**
   ```bash
   git clone <repository_url>
   cd progit_8
   ```

2. **Créer le fichier `.env`**
   ```bash
   cp .env.example .env
   ```

   Éditer `.env` et renseigner :
   ```env
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret
   ```

   Pour activer les emails transactionnels avec Resend, valider le domaine
   `progit.club` dans Resend puis configurer les variables SMTP listées dans
   `.env.example`. La seule valeur secrète est `SMTP_PASSWORD`, qui contient la
   clé API Resend et doit rester dans les variables d'environnement du serveur.

3. **Build des images Docker**
   ```bash
   make build
   ```

4. **Créer la base de données**
   ```bash
   make db-create
   make migrate
   ```

5. **Initialiser les données de test**
   ```bash
   make init
   ```

6. **Démarrer l'application**
   ```bash
   make up
   make attach
   ```

7. **Accéder à l'application**

   Ouvrir [http://localhost:3000](http://localhost:3000)

### Utilisateurs de test

Après `make init`, vous disposez de :

- **Admin** : admin@example.com / password123
- **Modérateur** : moderator@example.com / password123
- **Utilisateur** : user@example.com / password123

## Commandes Make

### Docker
- `make build` - Construire les images Docker
- `make up` - Démarrer les conteneurs (mode détaché)
- `make attach` - Se connecter aux logs du conteneur web
- `make down` - Arrêter et supprimer les conteneurs
- `make logs` - Suivre tous les logs

### Base de données
- `make db-create` - Créer les bases de données
- `make migrate` - Exécuter les migrations
- `make db-reset` - Supprimer, recréer et migrer
- `make db-seed` - Charger les seeds
- `make init` - Créer les utilisateurs de test

### Rails
- `make console` - Console Rails
- `make bash` - Shell bash dans le conteneur
- `make test` - Lancer les tests
- `make rubocop` - Lancer le linter
- `make rubocop-fix` - Corriger automatiquement les problèmes

## Base de données

L'application utilise **MariaDB externe** (hors Docker) :

- **Host** : `host.docker.internal` (ou `localhost` en local)
- **Port** : `3307` (pas le port par défaut 3306)
- **Bases** :
  - `progit_8_development`
  - `progit_8_test`
  - `progit_8_production`
- **Credentials** : `mariadb` / `mariadb` (dev/test)

## Authentification & Autorisation

### Système d'authentification

- **Rails 8 Authentication** (pas Devise)
- **Double authentification** : Email/Password + Google OAuth2
- **Auto-liaison** : Si un utilisateur se connecte avec Google et qu'un compte avec le même email existe, les comptes sont automatiquement liés
- **Session tracking** : `session[:login_method]` stocke "google" ou "password"

### Rôles et permissions

Trois rôles définis via enum :
- **user** (0) : Accès standard
- **moderator** (1) : Permissions étendues
- **admin** (2) : Accès complet

Gestion via CanCanCan dans `app/models/ability.rb`.

## Design System

### Palette de couleurs (Tailwind)

- **Backgrounds** : `bg-slate-900` (primaire), `bg-slate-800` (secondaire)
- **Bordures** : `border-slate-700`, `border-slate-600` (inputs)
- **Texte** : `text-white` (primaire), `text-slate-400` (secondaire), `text-slate-300` (labels)
- **Accent** : `blue-500` à `blue-600` (gradients autorisés)
- **Focus** : `ring-blue-500`

### Composants standards

- **Inputs** : `px-4 py-3`, `rounded-lg`, `bg-slate-700`, focus ring
- **Boutons** : Gradients subtils, `rounded-lg`, `hover:scale-[1.02]`
- **Cards** : `rounded-2xl`, `shadow-2xl`, `p-8`, border
- **Labels** : `text-sm font-medium`, `mb-2`

## Architecture

### Points clés

- **Turbo désactivé** : `Turbo.session.drive = false` pour meilleur contrôle
- **Formulaires** : Rechargement complet de page (pas de Turbo Frames)
- **Routes** :
  - `/user` (singulier) pour le profil de l'utilisateur connecté
  - `/stats/dashboard` pour le tableau de bord (accès public)
  - `/hike_paths/:id` pour visualiser un parcours (accès public)

### Modèles principaux

- **User** : Utilisateurs avec authentification double (password + OAuth)
- **Hike** : Randonnées avec métadonnées (distance, dénivelé, difficulté)
- **HikeHistory** : Historique des randonnées effectuées (date, guide, coût)
- **HikePath** : Coordonnées GPS des parcours

### Contrôleurs

- `ApplicationController` : Authentification, autorisation globale
- `HikesController` : CRUD randonnées
- `HikeHistoriesController` : Gestion historique
- `StatsController` : Statistiques et graphiques
- `UsersController` : Profil, inscription, liaison/dissociation Google
- `OmniauthCallbacksController` : Callbacks OAuth Google

## Fonctionnalités

### Gestion des randonnées

- Créer/modifier/supprimer des randonnées
- Ajouter des historiques (passées ou futures)
- Importer parcours depuis OpenRunner
- Visualiser sur carte interactive
- Filtrer et rechercher

### Tableau de bord

- Statistiques globales (total randonnées, distance, dénivelé)
- Graphiques mensuels (Chart.js)
- Top 10 guides
- Liste des dernières randonnées
- **Accès public** (pas de login requis)

### Gestion utilisateurs

- Inscription email/password
- Connexion Google OAuth2
- Liaison/dissociation de comptes
- Gestion de profil (avatar, surnom, mot de passe)
- Photos de profil Google redimensionnables

### Bannière "Prochaine randonnée"

- Affiche automatiquement la randonnée du jour ou suivante
- Informations : date, heure, lieu, guide, distance, dénivelé, coût
- Lien vers OpenRunner
- Bouton modification rapide

## Internationalisation

Application en **français** (locale par défaut : `fr`).

Traductions complètes pour :
- Pages d'authentification (login, signup, reset password)
- Page profil utilisateur
- Messages flash
- Formulaires

## Tests

```bash
make test
```

## Linting

```bash
make rubocop        # Vérifier
make rubocop-fix    # Corriger automatiquement
```

## Déploiement

`progit.club` tourne sur Coolify à partir d'une image construite par la CI.

Enchaînement sur un push vers `main` ([.github/workflows/ci.yml](./.github/workflows/ci.yml)) :

1. `scan_ruby` / `scan_js` / `lint`
2. `build` — construit le [Dockerfile](./Dockerfile) et pousse
   `docker-registry.sousa-dev.com/progit-8` avec deux tags : `latest` et le SHA du commit
3. `deploy` — ping l'API Coolify, qui tire `latest` et redémarre le service

Sur une PR, `build` construit l'image sans la pousser : le Dockerfile est validé avant le merge.

### Secrets GitHub requis

| Secret | Usage |
| --- | --- |
| `REGISTRY` | Hôte du registry (optionnel, défaut `docker-registry.sousa-dev.com`) |
| `REGISTRY_USERNAME` / `REGISTRY_PASSWORD` | Push de l'image |
| `COOLIFY_API_TOKEN` / `COOLIFY_DEPLOY_URL` | Déclenchement du redéploiement |

### Côté Coolify

La stack à utiliser est dans [deploy/coolify-compose.yml](./deploy/coolify-compose.yml). Elle
tire l'image du registry au lieu de la construire sur le serveur.

L'app tourne en `RAILS_ENV=production` (l'image est construite avec
`BUNDLE_WITHOUT=development`, elle ne peut pas démarrer en mode development), ce qui implique
les 4 bases déclarées dans [config/database.yml](./config/database.yml) : `DATABASE_NAME`,
`DATABASE_CACHE_NAME`, `DATABASE_QUEUE_NAME`, `DATABASE_CABLE_NAME`.

### Rollback

Remplacer `:latest` par `:<sha>` dans la stack Coolify et redéployer.

## Problèmes courants

1. **Port MariaDB** : Utiliser 3307, pas 3306
2. **Docker Compose V2** : `docker compose` (espace), pas `docker-compose` (tiret)
3. **Turbo désactivé** : Ne pas ajouter de fonctionnalités Turbo
4. **Utilisateurs OAuth sans password** : Vérifier `password_digest.present?`, pas juste `oauth_user?`
5. **Route profil** : `/user` (singulier), pas `/users/:id`

## Documentation

Voir [CLAUDE.md](./CLAUDE.md) pour :
- Instructions détaillées pour Claude Code
- Décisions architecturales
- Patterns de code
- Guide du design system
- Principes DRY/KISS/SLAP

## Contribution

1. Respecter le design system Tailwind (thème sombre)
2. Suivre les principes DRY/KISS/SLAP
3. Traduire tous les textes en français
4. Tester les modifications avec `make test`
5. Valider le code avec `make rubocop-fix`

## Licence

Propriétaire - Tous droits réservés
