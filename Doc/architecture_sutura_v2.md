# Architecture technique — Sutura V2

> Document de référence pour le backend de Sutura V2.  
> État : proposition de conception initiale, à valider au fil du développement.

## 1. Contexte et objectifs

Sutura est une application Android de gestion d'atelier de couture destinée aux couturiers indépendants. La première version vise un couturier qui travaille seul, avec un seul appareil principal. L'application doit permettre de gérer les clients, leurs mensurations, les modèles de vêtements, les commandes et les échéances.

Le backend est développé et testé localement avant son déploiement. L'application mobile Flutter sera raccordée après stabilisation des premières API.

### Décisions de départ

| Élément | Décision |
|---|---|
| IDE | Visual Studio Code |
| Backend | ASP.NET Core Web API avec contrôleurs MVC |
| Framework | .NET 10 |
| Langage | C# |
| Base de données | PostgreSQL local |
| ORM | Entity Framework Core 10 |
| Accès aux données | EF Core + migrations |
| Authentification | ASP.NET Core Identity + JWT |
| Contrat HTTP | REST, préfixe `/api/v1` |
| Documentation API | Swagger / OpenAPI |
| Fichiers | Google Drive pour les photos et les sauvegardes, avec métadonnées en base |
| Mode de travail initial | Développement local, backend d'abord |

Le choix d'une API avec contrôleurs MVC ne signifie pas qu'il faut créer des vues Razor : les contrôleurs renvoient du JSON et servent le client Flutter.

## 2. Architecture retenue

Utiliser une **Clean Architecture pragmatique**, avec quatre projets. Elle sépare les règles métier de la base de données, de Google Drive et du protocole HTTP sans introduire prématurément une architecture complexe.

```text
SuturaV2/
├── Sutura.sln
├── src/
│   ├── Sutura.API/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   ├── Extensions/
│   │   ├── Filters/
│   │   ├── Configuration/
│   │   └── Program.cs
│   ├── Sutura.Application/
│   │   ├── DTOs/
│   │   ├── Interfaces/
│   │   ├── Features/
│   │   │   ├── Auth/
│   │   │   ├── Clients/
│   │   │   ├── Measurements/
│   │   │   ├── Models/
│   │   │   ├── Orders/
│   │   │   └── Backups/
│   │   ├── Validators/
│   │   └── Mapping/
│   ├── Sutura.Domain/
│   │   ├── Entities/
│   │   ├── Enums/
│   │   ├── ValueObjects/
│   │   └── Common/
│   └── Sutura.Infrastructure/
│       ├── Persistence/
│       │   ├── SuturaDbContext.cs
│       │   ├── Configurations/
│       │   └── Migrations/
│       ├── Identity/
│       ├── Repositories/
│       ├── GoogleDrive/
│       └── DependencyInjection.cs
└── tests/
    ├── Sutura.UnitTests/
    └── Sutura.IntegrationTests/
```

### Responsabilités

- **Sutura.Domain** : entités, enums, règles métier et objets de valeur. Aucune dépendance vers EF Core, ASP.NET ou Google Drive.
- **Sutura.Application** : cas d'utilisation, DTO, contrats/interfaces, validation et orchestration. Elle dépend de Domain.
- **Sutura.Infrastructure** : implémentations techniques : EF Core, PostgreSQL, Identity, dépôts et Google Drive. Elle dépend de Application et Domain.
- **Sutura.API** : entrée HTTP, contrôleurs, authentification JWT, configuration, Swagger et gestion globale des erreurs. Elle assemble les dépendances.

Dépendances autorisées :

```text
Sutura.Domain       ← aucune dépendance vers les autres projets
Sutura.Application  → Sutura.Domain
Sutura.Infrastructure → Sutura.Application + Sutura.Domain
Sutura.API          → Sutura.Application + Sutura.Infrastructure
```

## 3. Où stocker les modèles ?

Le mot « modèle » peut désigner deux choses différentes :

1. **Modèles de code C#** : les entités métier sont dans `Sutura.Domain/Entities/`. Les DTO destinés aux requêtes/réponses HTTP sont dans `Sutura.Application/DTOs/`. Les configurations EF Core sont dans `Sutura.Infrastructure/Persistence/Configurations/`.
2. **Modèles de vêtements et leurs photos** : les informations sont enregistrées dans PostgreSQL (`ClothingModels`) et les photos dans Google Drive. La base conserve l'identifiant Drive, le nom du fichier et ses métadonnées, pas les octets de l'image.

Ne place pas les classes métier dans `Controllers`, et ne confonds pas une entité EF Core avec un DTO d'API.

## 4. Flux général d'une requête

```text
Flutter
  │ HTTPS + JWT
  ▼
Sutura.API (Controller)
  ▼
Sutura.Application (use case / service)
  ▼
Interfaces (repositories / file storage)
  ▼
Sutura.Infrastructure
  ├── EF Core ── PostgreSQL
  └── Google Drive API
```

Un contrôleur doit rester mince : vérifier la requête, appeler un cas d'utilisation et retourner le code HTTP adapté. Les règles métier ne doivent pas être écrites dans le contrôleur.

## 5. Conventions de code

- Noms de classes et propriétés en anglais ; commentaires et documentation pédagogique possibles en français.
- `PascalCase` pour classes/propriétés/méthodes publiques ; `camelCase` pour variables et paramètres.
- DTO séparés des entités.
- `CancellationToken` sur les opérations asynchrones d'accès réseau/base.
- `DateTimeOffset` pour les dates/horodatages ; stocker les dates en UTC côté serveur.
- Montants en `numeric(12,2)` / `decimal`, jamais en `float` ou `double`.
- Identifiants UUID (`Guid`) pour les ressources exposées par l'API.
- Pagination sur les listes ; limites de taille explicites.
- Erreurs cohérentes au format `ProblemDetails`.
- Validation côté API et contraintes côté base de données.

## 6. Authentification et propriété des données

Chaque atelier possède un compte utilisateur personnel. Même si le MVP est utilisé par une seule personne sur un seul appareil, chaque donnée métier doit être liée à `UserId`. Cela évite de devoir réécrire le modèle si plusieurs comptes sont ajoutés plus tard.

- ASP.NET Core Identity gère les comptes et mots de passe.
- JWT Bearer protège les endpoints.
- Les endpoints métier filtrent systématiquement par l'utilisateur authentifié.
- Ne jamais accepter un `UserId` fourni librement par le client pour déterminer le propriétaire d'une ressource.
- Les secrets et clés ne sont jamais committés dans Git.

Le renouvellement de jeton (refresh token) sera ajouté avec une stratégie de révocation et de rotation ; ne pas conserver un refresh token en clair.

## 7. Stockage et sauvegardes

- PostgreSQL local pendant le développement.
- En production, PostgreSQL sur un serveur adapté.
- Google Drive reçoit les photos de modèles et les sauvegardes exportées.
- La base conserve les identifiants Drive et les métadonnées nécessaires.
- Les fichiers Drive restent privés ; aucun lien public n'est nécessaire.
- Une sauvegarde n'est considérée valide qu'après export, envoi réussi et vérification de la présence du fichier.

Google Drive n'est pas un substitut à PostgreSQL : les données relationnelles restent dans la base. La sauvegarde doit exporter la base (par exemple avec `pg_dump`) et inclure un manifeste permettant d'identifier la version, la date et le contenu.

## 8. Ce qui est volontairement reporté

- Architecture microservices.
- CQRS/MediatR si aucun besoin concret ne le justifie.
- Redis et files de messages.
- Synchronisation multi-appareils et résolution de conflits.
- Multi-atelier avancé et rôles employés.
- Paiements en ligne.
- Gestion comptable avancée.

## 9. Critères de qualité avant intégration Flutter

- La base peut être créée depuis zéro avec les migrations.
- Les endpoints principaux sont testés via Swagger ou tests automatisés.
- Les données d'un utilisateur ne sont jamais accessibles à un autre.
- Les validations et erreurs sont documentées.
- Les photos restent privées dans Drive.
- Une sauvegarde peut être restaurée sur une base de test.
