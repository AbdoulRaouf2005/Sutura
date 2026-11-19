# Feuille de route de développement — Sutura V2

> Plan progressif pour construire et tester le backend local avant l'intégration Flutter.  
> Enveloppe de travail indicative : avancer par petites sessions, sans chercher à tout coder d'un seul coup.

## Vue d'ensemble

| Phase | Résultat attendu |
|---|---|
| 0. Préparation | Solution .NET et environnement local prêts |
| 1. Fondation | Architecture, PostgreSQL, EF Core et migrations |
| 2. Authentification | Inscription, connexion, JWT et isolation des comptes |
| 3. Clients et mensurations | Fiches clients et mesures |
| 4. Modèles et photos | Catalogue et Google Drive photo |
| 5. Commandes | Cycle de vie et instantané des mesures |
| 6. Sauvegardes | Export PostgreSQL et envoi Drive |
| 7. Qualité | Tests, sécurité, documentation et stabilisation |
| 8. Intégration Flutter | Connexion du mobile à l'API |

---

## Phase 0 — Préparer l'environnement

**Objectif :** pouvoir compiler et lancer une API vide en .NET 10.

- [ ] Vérifier `dotnet --info` et le SDK .NET 10.
- [ ] Vérifier PostgreSQL local et créer un utilisateur/base de développement.
- [ ] Installer les extensions VS Code utiles : C#, C# Dev Kit, PostgreSQL.
- [ ] Créer le dépôt Git et un `.gitignore` .NET.
- [ ] Créer `Sutura.sln` et les quatre projets.
- [ ] Ajouter les références entre projets selon le document d'architecture.
- [ ] Ajouter les packages EF Core 10, Npgsql EF Core PostgreSQL, Identity EF Core, JWT Bearer, EF Design, Swagger/OpenAPI et les outils de scaffolding uniquement si nécessaires.
- [ ] Installer les outils `dotnet-ef` version 10 ; `dotnet-aspnet-codegenerator` et `Microsoft.VisualStudio.Web.CodeGeneration.Design` seulement si tu utilises réellement le scaffolding.
- [ ] Lancer l'API et ouvrir Swagger.

**Validation :** `dotnet build` réussit et l'API démarre sans erreur.

## Phase 1 — Fondation et base de données

**Objectif :** créer une base propre et reproductible.

- [ ] Ajouter `ApplicationUser : IdentityUser<Guid>`.
- [ ] Créer `SuturaDbContext`.
- [ ] Ajouter les entités et configurations EF Core progressivement.
- [ ] Configurer PostgreSQL dans `Program.cs` via les options.
- [ ] Placer la chaîne de connexion dans User Secrets ou variables d'environnement.
- [ ] Générer la première migration.
- [ ] Appliquer la migration sur une base vide.
- [ ] Vérifier les tables dans pgAdmin ou psql.
- [ ] Ajouter un endpoint de santé non sensible (`/health`).

**Validation :** la base est entièrement reconstruisible avec `dotnet ef database update`.

## Phase 2 — Authentification et sécurité

**Objectif :** protéger les données dès le départ.

- [ ] Configurer ASP.NET Core Identity.
- [ ] Créer les DTO register/login.
- [ ] Implémenter inscription et connexion.
- [ ] Générer et valider les JWT.
- [ ] Ajouter refresh token hashé, rotation et révocation.
- [ ] Protéger les contrôleurs.
- [ ] Tester les erreurs 400, 401 et 403.
- [ ] Créer deux comptes de test et vérifier qu'ils ne voient jamais les données l'un de l'autre.

**Validation :** un compte ne peut lire ni modifier aucune ressource d'un autre compte.

## Phase 3 — Clients et mensurations

**Objectif :** gérer le carnet client numérique.

- [ ] Confirmer avec le couturier la liste exacte des mensurations et leurs unités.
- [ ] Créer les définitions de mensurations.
- [ ] Créer les opérations CRUD des clients.
- [ ] Ajouter recherche par nom/téléphone et pagination.
- [ ] Enregistrer/mettre à jour les mensurations.
- [ ] Définir si l'historique des mensurations est conservé.
- [ ] Tester les validations et les appartenances utilisateur.

**Validation :** créer un client, retrouver sa fiche et enregistrer ses mesures depuis Swagger.

## Phase 4 — Modèles de vêtements et photos

**Objectif :** construire la galerie de références.

- [ ] Créer CRUD des modèles.
- [ ] Créer les tables `ModelPhotos` et `DriveFiles`.
- [ ] Créer un projet Google Cloud et activer Google Drive API.
- [ ] Configurer l'écran de consentement OAuth et les identifiants.
- [ ] Implémenter le flux OAuth et le stockage sécurisé du refresh token.
- [ ] Créer le dossier racine `Sutura/ModelPhotos`.
- [ ] Implémenter upload, affichage sécurisé et suppression des photos.
- [ ] Garantir une seule photo principale par modèle.
- [ ] Tester les erreurs Drive et les fichiers trop volumineux.

**Validation :** une photo ajoutée à un modèle est privée dans Drive et réaffichable via l'API.

## Phase 5 — Commandes

**Objectif :** suivre le travail de couture et les délais.

- [ ] Créer l'entité `Order` et ses configurations.
- [ ] Générer un numéro de commande unique par compte.
- [ ] Lier client et modèle.
- [ ] Copier les mensurations vers `OrderMeasurementSnapshots`.
- [ ] Implémenter création, consultation et modification.
- [ ] Implémenter les transitions de statut.
- [ ] Ajouter filtres par statut et date de livraison.
- [ ] Ajouter la liste des commandes à livrer prochainement.
- [ ] Confirmer le fonctionnement des paiements avant de créer `Payments`.

**Validation :** créer une commande complète et vérifier que ses mesures ne changent pas lorsque la fiche client est modifiée.

## Phase 6 — Sauvegardes Google Drive

**Objectif :** protéger les données du couturier.

- [ ] Générer un export PostgreSQL avec `pg_dump`.
- [ ] Créer le manifeste de sauvegarde.
- [ ] Calculer SHA-256.
- [ ] Envoyer dump et manifeste dans `Sutura/Backups`.
- [ ] Enregistrer l'historique dans `BackupRecords`.
- [ ] Définir la rétention et la fréquence.
- [ ] Tester une restauration sur une base temporaire.
- [ ] Simuler une panne réseau et vérifier que la sauvegarde passe en échec sans corrompre les données.

**Validation :** restaurer une sauvegarde complète sur une base de test.

## Phase 7 — Qualité et stabilisation

- [ ] Ajouter des tests unitaires aux règles métier.
- [ ] Ajouter des tests d'intégration avec PostgreSQL.
- [ ] Tester l'autorisation sur tous les endpoints.
- [ ] Ajouter validation des fichiers et limites d'upload.
- [ ] Configurer logs structurés sans secrets.
- [ ] Uniformiser `ProblemDetails`.
- [ ] Documenter les variables d'environnement.
- [ ] Préparer un jeu de données de démonstration.
- [ ] Vérifier les migrations depuis une base vide.
- [ ] Faire une revue de sécurité avant exposition sur Internet.

**Validation :** les scénarios principaux sont reproductibles et les erreurs sont compréhensibles.

## Phase 8 — Intégration Flutter

À commencer lorsque les endpoints essentiels sont stables.

- [ ] Définir la configuration `baseUrl` par environnement.
- [ ] Créer un client HTTP centralisé.
- [ ] Stocker les jetons dans un stockage sécurisé du téléphone.
- [ ] Implémenter login/logout et renouvellement de jeton.
- [ ] Connecter les écrans clients, mensurations, modèles et commandes.
- [ ] Prévoir états de chargement, erreurs et absence de réseau.
- [ ] Mettre en place le cache local nécessaire à l'expérience offline-first.
- [ ] Définir la stratégie de synchronisation avant de coder la synchronisation complète.

Attention : l'objectif offline-first implique une base locale côté Flutter et une stratégie de synchronisation. Le backend seul ne fournit pas le mode hors ligne.

## Routine de travail conseillée

Pour chaque fonctionnalité :

1. Lire le besoin et écrire les règles métier.
2. Créer/modifier l'entité Domain.
3. Ajouter la configuration EF Core et la migration.
4. Créer les DTO et interfaces Application.
5. Implémenter le cas d'utilisation.
6. Créer le contrôleur API.
7. Tester avec Swagger et un test automatisé.
8. Mettre à jour `api_specification.md`.

Évite de développer toutes les tables et tous les endpoints en une seule fois. Termine une fonctionnalité verticalement avant de passer à la suivante.

## Première tâche concrète

Commence par la Phase 0 et ne développe pas encore Google Drive. Le premier jalon doit être une solution qui compile, démarre et se connecte à PostgreSQL. Ensuite seulement, construis Identity et les premières migrations.
