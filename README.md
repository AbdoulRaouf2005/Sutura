# Sutura

**Mon atelier, bien géré.**

Sutura est une application mobile de gestion d'atelier de couture. Elle aide un couturier indépendant à organiser ses clients, ses mensurations, ses modèles de vêtements, ses commandes et ses paiements, en remplaçant progressivement les notes papier.

La V1 fonctionne **hors ligne**, sans backend : toutes les données métier (base SQLite et photos) restent sur l'appareil.

---

## Fonctionnalités

- **Tableau de bord** : commandes en cours, livraisons à venir, retards, montant restant à encaisser et raccourcis.
- **Clients** : création, modification, recherche par nom ou téléphone, archivage, historique des commandes.
- **Mensurations** : plusieurs jeux de mesures par client, historisés sans écrasement.
- **Galerie de modèles** : collection personnelle avec photo (appareil photo ou galerie), catégorie, recherche et filtres.
- **Commandes** : client, modèle facultatif, mensurations de référence, quantité, prix, date de livraison et statut.
- **Paiements** : avances et versements multiples, calcul du total payé et du reste à payer.
- **Réglages** : thème clair/sombre/système, devise, unité de mesure et sauvegarde/restauration locale.
- **Sauvegarde** : export `.zip` de la base `sutura.db` et des photos, partage via le système, restauration depuis un fichier.

Statuts de commande : `À commencer`, `En cours`, `Prête`, `Livrée`, `Annulée`. L'état **En retard** est calculé (date de livraison dépassée, commande ni livrée ni annulée), il n'est pas enregistré.

---

## Stack technique

| Élément | Choix |
|---|---|
| Framework | Flutter / Dart (SDK `^3.13.1`) |
| Stockage local | SQLite via `sqflite` |
| Navigation | `go_router` (`StatefulShellRoute` à 4 branches) |
| Photos | `image_picker`, copiées dans le stockage privé de l'application |
| Sauvegarde | `archive`, `file_picker`, `share_plus`, `path_provider` |
| Préférences | `shared_preferences` |
| Identifiants | `uuid` |
| Dates / montants | `intl` |

Aucun backend ni synchronisation réseau n'est utilisé dans la V1.

---

## Structure du projet

```text
sutura/
├── docs/                      # Cahier des charges et spécifications (dont backend V2)
├── lib/
│   ├── main.dart              # Bootstrap : localisation, thème, écran de chargement
│   ├── app/                   # Application, shell de navigation, routeur
│   ├── core/
│   │   ├── database/          # AppDatabase + migrations SQLite
│   │   ├── repositories/      # Accès aux données par entité
│   │   ├── services/          # Sauvegarde / restauration
│   │   ├── state/             # DataController et rafraîchissement
│   │   ├── storage/           # Stockage local des images
│   │   ├── theme/             # Couleurs, thèmes clair/sombre, contrôleur
│   │   └── utils/             # Générateur d'identifiants
│   ├── features/              # dashboard, clients, measurements, gallery,
│   │                          # orders, payments, settings
│   └── shared/                # Widgets et formatters réutilisables
├── assets/logo/               # Icône et logo de chargement
├── test/                      # Tests des modèles et règles métier
└── pubspec.yaml
```

---

## Démarrage

### Prérequis

- Flutter SDK installé (`flutter --version`)
- Un appareil ou émulateur Android (cible principale de la V1)

### Installation et lancement

```bash
flutter pub get
flutter run
```

### Tests et qualité

```bash
flutter analyze
flutter test
```

Les tests couvrent notamment les modèles clients, mensurations, modèles de vêtements, commandes, paiements et le thème.

---

## Icône et écran de démarrage

L'icône et le splash natif sont générés depuis `assets/logo/` :

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Couleur de marque : vert profond `#0F5132`.

---

## Palette et thème

| Nom | Code HEX | Usage |
|---|---|---|
| Vert profond | `#0F5132` | Couleur principale (AppBar, actions, marque) |
| Or africain | `#F4B400` | Accent, éléments sélectionnés |
| Orange terre | `#E76F51` | Alertes non critiques, retards |
| Crème | `#FAF7F0` | Fond principal |
| Gris foncé | `#2E2E2E` | Texte principal |

Les couleurs sémantiques (succès, avertissement, erreur, texte secondaire) sont exposées par `AppSemanticColors` et s'adaptent au mode sombre.

---

## Données et confidentialité

- Base SQLite : `sutura.db` dans le répertoire de bases de l'application.
- Photos : répertoire privé `garment_images/`.
- Clés étrangères activées (`PRAGMA foreign_keys = ON`), dates en ISO 8601, montants en entiers (FCFA).
- Les migrations sont versionnées dans `lib/core/database/database_migrations.dart`.
- Une désinstallation ou une perte du téléphone entraîne la perte des données : effectuer régulièrement une sauvegarde depuis **Réglages**.

---

## Documentation

- [`cahier_charge.md`](cahier_charge.md) — cahier des charges fonctionnel et technique de la V1.
- [`guide_conception_sutura.md`](guide_conception_sutura.md) — identité visuelle, thème, conventions et structure.
- [`docs/sutura-backend-v2.md`](docs/sutura-backend-v2.md) — spécification du backend V2 (ASP.NET Core 10 + PostgreSQL + Swagger).

---

## Feuille de route

- **V1 (actuelle)** : application Flutter 100 % hors ligne avec SQLite.
- **V2 (spécifiée)** : backend ASP.NET Core 10, PostgreSQL et synchronisation, tout en conservant SQLite comme stockage local.
