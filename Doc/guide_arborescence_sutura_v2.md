# Guide de l'arborescence — Sutura V2

Ce guide explique le rôle des dossiers du backend Sutura V2, ce qu'ils contiennent et quand les utiliser.

Architecture : ASP.NET Core Web API avec contrôleurs MVC, .NET 10, Clean Architecture pragmatique, EF Core et PostgreSQL.

## 1. Vue générale

```text
SuturaV2/
├── Sutura.sln
├── src/
│   ├── Sutura.API/
│   ├── Sutura.Application/
│   ├── Sutura.Domain/
│   └── Sutura.Infrastructure/
├── tests/
│   ├── Sutura.UnitTests/
│   └── Sutura.IntegrationTests/
├── .gitignore
└── README.md
```

| Élément | Utilité |
|---|---|
| `Sutura.sln` | Regroupe les projets .NET dans une seule solution. |
| `src/` | Contient le code de l'application. |
| `tests/` | Contient les tests automatisés. |
| `.gitignore` | Exclut de Git les fichiers générés, secrets et fichiers temporaires. |
| `README.md` | Explique le projet, les prérequis et les commandes de démarrage. |

## 2. `Sutura.Domain/` — Le cœur métier

Ce projet décrit le métier de la couture. Il ne doit pas dépendre d'ASP.NET Core, d'EF Core, de PostgreSQL ou de Google Drive.

```text
Sutura.Domain/
├── Entities/
├── Enums/
├── ValueObjects/
└── Common/
```

### `Entities/`

Contient les objets métier qui possèdent une identité et un cycle de vie.

Exemples : `Client.cs`, `Order.cs`, `ClothingModel.cs`, `ClientMeasurement.cs`.

À utiliser lorsque tu crées un concept métier durable : client, commande, modèle de vêtement, mensuration.

### `Enums/`

Contient les listes fermées de valeurs métier.

Exemples : `OrderStatus.cs` (`Pending`, `InProgress`, `Ready`, `Delivered`, `Cancelled`) et `BackupStatus.cs`.

À utiliser lorsqu'une propriété ne peut prendre qu'un ensemble limité de valeurs. Une catégorie que le couturier peut créer librement doit plutôt être stockée en base.

### `ValueObjects/`

Contient des objets définis par leurs valeurs plutôt que par un identifiant indépendant.

Exemples possibles : `Money.cs` (montant + devise), `MeasurementValue.cs` (valeur + unité).

À utiliser lorsqu'un ensemble de propriétés forme une notion cohérente qui doit être validée ensemble. N'en crée pas systématiquement pour chaque propriété.

### `Common/`

Contient les éléments réellement partagés par plusieurs entités, par exemple `BaseEntity.cs` ou `AuditableEntity.cs`.

**Ne place pas dans Domain :** contrôleurs, DTO HTTP, `DbContext`, appels Google Drive, chaînes de connexion ou code lié aux requêtes HTTP.

## 3. `Sutura.Application/` — Les cas d'utilisation

Ce projet organise les actions que Sutura sait effectuer. Il orchestre les opérations métier et définit les contrats dont il a besoin.

```text
Sutura.Application/
├── DTOs/
├── Interfaces/
├── Features/
│   ├── Auth/
│   ├── Clients/
│   ├── Measurements/
│   ├── Models/
│   ├── Orders/
│   └── Backups/
├── Validators/
└── Mapping/
```

### `DTOs/`

DTO signifie *Data Transfer Object*. Ces classes définissent les données reçues ou renvoyées par l'API.

Exemples : `CreateClientRequest.cs`, `UpdateClientRequest.cs`, `ClientResponse.cs`, `OrderResponse.cs`.

À utiliser pour définir les données échangées entre Flutter et l'API. Ne renvoie pas directement les entités EF Core au mobile : les DTO évitent d'exposer les propriétés internes.

### `Interfaces/`

Contient les contrats des capacités techniques dont Application a besoin.

Exemples : `IClientRepository.cs`, `IOrderRepository.cs`, `IFileStorageService.cs`, `ITokenService.cs`.

À utiliser lorsqu'Application a besoin d'une opération sans devoir connaître son implémentation. Par exemple, Application demande à `IFileStorageService` d'enregistrer une photo sans savoir si elle sera stockée sur Google Drive.

### `Features/`

Regroupe le code par fonctionnalité métier.

| Dossier | Contenu |
|---|---|
| `Auth/` | Inscription, connexion, renouvellement et révocation des jetons. |
| `Clients/` | Création, modification, consultation, recherche et archivage des clients. |
| `Measurements/` | Catalogue et enregistrement des mensurations. |
| `Models/` | Catalogue des modèles et gestion des photos associées. |
| `Orders/` | Création, consultation, modification et statut des commandes. |
| `Backups/` | Déclenchement et suivi des sauvegardes. |

Exemple :

```text
Features/
└── Clients/
    ├── CreateClient/
    │   └── CreateClientService.cs
    ├── UpdateClient/
    │   └── UpdateClientService.cs
    └── GetClients/
        └── GetClientsService.cs
```

Tu peux commencer plus simplement avec un `ClientService.cs` dans `Clients/`. Crée des sous-dossiers seulement lorsque le volume de code le justifie.

### `Validators/`

Contient les validations des entrées : prénom obligatoire, numéro de téléphone valide, prix positif ou nul, date cohérente.

La validation des entrées ne remplace ni les règles métier de Domain ni les contraintes de PostgreSQL.

### `Mapping/`

Contient les conversions répétitives entre DTO et objets métier, par exemple `CreateClientRequest` vers `Client`, ou `Client` vers `ClientResponse`.

Pour quelques propriétés, une conversion manuelle est souvent suffisante.

**Ne place pas dans Application :** contrôleurs ASP.NET, implémentations concrètes de `DbContext`, appels directs à Google Drive ou chaînes de connexion.

## 4. `Sutura.Infrastructure/` — Les implémentations techniques

Ce projet connecte les contrats d'Application aux technologies réelles : EF Core, PostgreSQL, Identity et Google Drive.

```text
Sutura.Infrastructure/
├── Persistence/
│   ├── SuturaDbContext.cs
│   ├── Configurations/
│   └── Migrations/
├── Identity/
├── Repositories/
├── GoogleDrive/
└── DependencyInjection.cs
```

### `Persistence/`

Contient la persistance relationnelle avec Entity Framework Core.

- `SuturaDbContext.cs` : point d'entrée EF Core vers la base. Il expose les `DbSet` et configure l'accès aux tables. Si Identity est utilisé avec une clé `Guid`, le contexte peut hériter de la classe `IdentityDbContext` générique adaptée.
- `Configurations/` : configuration EF Core de chaque entité avec `IEntityTypeConfiguration<T>`. Exemple : `ClientConfiguration.cs` définit les longueurs, index, relations et contraintes.
- `Migrations/` : migrations générées par EF Core qui décrivent l'évolution du schéma PostgreSQL.

Commandes usuelles :

```bash
dotnet ef migrations add InitialCreate --project src/Sutura.Infrastructure --startup-project src/Sutura.API

dotnet ef database update --project src/Sutura.Infrastructure --startup-project src/Sutura.API
```

À utiliser lorsque tu crées ou modifies les tables et souhaites versionner l'évolution de la base. Ne modifie pas une migration déjà appliquée sur un environnement partagé : crée-en une nouvelle.

### `Identity/`

Contient les implémentations techniques liées aux comptes et à l'authentification : configuration Identity, gestion des utilisateurs ou stockage sécurisé des refresh tokens.

Les DTO d'inscription/connexion restent dans Application et les routes HTTP restent dans API.

### `Repositories/`

Contient les implémentations concrètes des interfaces de dépôt définies dans Application.

Exemples : `ClientRepository.cs`, `OrderRepository.cs`. Ces classes utilisent `SuturaDbContext` pour interroger ou modifier PostgreSQL.

Ne crée pas obligatoirement un repository générique pour chaque table : ajoute une abstraction lorsqu'elle simplifie réellement le code.

### `GoogleDrive/`

Contient le code qui communique réellement avec l'API Google Drive.

Exemples :
- `GoogleDriveService.cs` : upload, téléchargement et suppression ;
- `GoogleOAuthService.cs` : échange et renouvellement des jetons ;
- `GoogleDriveOptions.cs` : paramètres de configuration ;
- `DriveFolderManager.cs` : gestion des dossiers de l'application.

À utiliser lorsque tu commences l'intégration Drive. Le code métier passe par une interface déclarée dans Application, jamais par un appel direct à la bibliothèque Google.

### `DependencyInjection.cs`

Enregistre les implémentations dans le conteneur d'injection de dépendances.

Exemple :

```csharp
services.AddScoped<IClientRepository, ClientRepository>();
services.AddScoped<IFileStorageService, GoogleDriveService>();
```

À utiliser lorsque tu ajoutes une implémentation technique à connecter à l'application.

## 5. `Sutura.API/` — Le point d'entrée HTTP

Ce projet reçoit les requêtes Flutter, applique les mécanismes HTTP et transmet le travail à Application.

```text
Sutura.API/
├── Controllers/
├── Middleware/
├── Extensions/
├── Filters/
├── Configuration/
└── Program.cs
```

### `Controllers/`

Contient les contrôleurs REST : `AuthController.cs`, `ClientsController.cs`, `MeasurementsController.cs`, `ModelsController.cs`, `OrdersController.cs`, `BackupsController.cs`.

Un contrôleur reçoit la requête, appelle Application et retourne une réponse HTTP. Il doit rester mince : pas de logique métier volumineuse ni de SQL directement dans le contrôleur.

### `Middleware/`

Contient les composants qui interviennent sur plusieurs requêtes HTTP, par exemple la gestion globale des exceptions ou l'ajout d'informations de corrélation aux logs.

À utiliser lorsqu'un traitement doit être commun à plusieurs routes.

### `Extensions/`

Contient des méthodes d'extension qui organisent la configuration de l'API : `AddApiServices()`, `AddSwaggerConfiguration()`, `UseApiPipeline()`.

À utiliser lorsque `Program.cs` devient trop long.

### `Filters/`

Contient les filtres MVC, lorsqu'un traitement doit intervenir à une étape précise de l'exécution d'une action ou d'un contrôleur.

Ne crée pas un filtre pour remplacer une validation DTO ordinaire.

### `Configuration/`

Contient les classes représentant les paramètres de configuration : options JWT, limites d'upload, options Swagger.

Les valeurs sensibles viennent de .NET User Secrets ou des variables d'environnement, jamais de secrets écrits en clair dans Git.

### `Program.cs`

Point de démarrage de l'application. Il configure l'injection de dépendances, PostgreSQL, Identity, JWT, Swagger, le pipeline HTTP et les contrôleurs.

Garde-le lisible et déplace les blocs de configuration volumineux dans des extensions lorsque cela devient utile.

## 6. `tests/` — Vérifier le fonctionnement

```text
tests/
├── Sutura.UnitTests/
└── Sutura.IntegrationTests/
```

### `Sutura.UnitTests/`

Tests unitaires d'une règle ou d'une classe isolée, sans démarrer toute l'application ni dépendre d'une vraie base.

Exemples : rejet d'un prix négatif, transition de statut interdite, calcul du reste à payer si la gestion des paiements est retenue.

### `Sutura.IntegrationTests/`

Tests de plusieurs composants ensemble.

Exemples : création d'un client par HTTP et persistance PostgreSQL, isolation entre deux comptes, fonctionnement des migrations sur une base de test.

## 7. Où placer un fichier ?

| Fichier à créer | Emplacement |
|---|---|
| `Client.cs` | `Domain/Entities/` |
| `OrderStatus.cs` | `Domain/Enums/` |
| `CreateClientRequest.cs` | `Application/DTOs/` |
| `IClientRepository.cs` | `Application/Interfaces/` |
| `ClientService.cs` | `Application/Features/Clients/` |
| `ClientConfiguration.cs` | `Infrastructure/Persistence/Configurations/` |
| `SuturaDbContext.cs` | `Infrastructure/Persistence/` |
| `ClientRepository.cs` | `Infrastructure/Repositories/` |
| `GoogleDriveService.cs` | `Infrastructure/GoogleDrive/` |
| `ClientsController.cs` | `API/Controllers/` |
| `ExceptionHandlingMiddleware.cs` | `API/Middleware/` |
| Test d'une règle de commande | `tests/Sutura.UnitTests/` |
| Test HTTP de création client | `tests/Sutura.IntegrationTests/` |

Tu peux choisir de ranger certains DTO et validateurs dans le dossier de leur fonctionnalité au lieu d'un dossier global. L'important est de garder une convention constante.

## 8. Exemple : création d'un client depuis Flutter

```text
Flutter
  │ POST /api/v1/clients
  ▼
API/Controllers/ClientsController.cs
  │ appelle Application
  ▼
Application/Features/Clients/ClientService.cs
  │ applique le cas d'utilisation
  ▼
Domain/Entities/Client.cs
  │ représente le client et ses règles
  ▼
Application/Interfaces/IClientRepository.cs
  │ définit le contrat
  ▼
Infrastructure/Repositories/ClientRepository.cs
  │ utilise EF Core
  ▼
Infrastructure/Persistence/SuturaDbContext.cs
  │
  ▼
PostgreSQL
  │
  ▼
API retourne HTTP 201 Created à Flutter
```

Ce parcours est conceptuel. Selon l'implémentation, le service Application peut utiliser un repository ou une abstraction de contexte. Choisis une stratégie cohérente plutôt que de multiplier les couches.

## 9. Les règles à retenir

1. **Domain** décrit le métier, pas les technologies.
2. **Application** décrit les actions que Sutura peut effectuer.
3. **Infrastructure** réalise les opérations techniques.
4. **API** expose les fonctionnalités au client Flutter.
5. **Tests** vérifient les règles et les échanges.
6. Domain ne dépend jamais d'Infrastructure ou d'API.
7. Place une classe selon sa responsabilité, pas selon le dossier qui semble le plus pratique.
8. Ne crée pas tous les dossiers vides dès le premier jour : crée-les au moment où une fonctionnalité en a besoin.

## 10. Ordre conseillé pour créer les dossiers

1. Créer la solution et les quatre projets.
2. Commencer par `Domain/Entities` et `Application/Features`.
3. Ajouter `Infrastructure/Persistence` pour PostgreSQL et les migrations.
4. Ajouter `API/Controllers` pour exposer les premières routes.
5. Ajouter les tests dès que les premières règles sont en place.
6. Créer `Infrastructure/GoogleDrive` seulement au moment de l'intégration Drive.

**À retenir :** un bon découpage ne se mesure pas au nombre de dossiers. Il se mesure à la facilité avec laquelle tu retrouves une responsabilité, modifies une fonctionnalité et testes ton code sans casser le reste.
