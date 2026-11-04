# Sutura V2 — Backend ASP.NET Core 10 + PostgreSQL + Swagger

**Document d'implémentation**

- **Projet :** Sutura — gestion d'atelier de couture
- **Version :** 2.0
- **Backend :** ASP.NET Core 10 Web API, PostgreSQL, Swagger
- **App :** Flutter offline-first, SQLite conservé comme stockage local
- **Date :** novembre 2026

> Ce document décrit les étapes de réalisation, tous les modèles du domaine et tous les DTOs à créer. Il ne contient pas l'implémentation réelle : il sert de spécification de développement.

---

## Sommaire

1. Prérequis
2. Étapes de mise en place
3. Modèles du domaine
4. Entités d'authentification
5. DTOs
6. Règles métier et validation
7. Configurations EF Core
8. Contrôleurs, services et endpoints
9. Tests
10. Déploiement VPS
11. Critères d'acceptation

---

# 1. Prérequis

| Élément | Version / choix |
|---|---|
| .NET SDK | 10 (déjà installé) |
| PostgreSQL | 17, local ou via Docker |
| Docker Desktop | Recommandé pour PostgreSQL + MinIO |
| IDE | Visual Studio 2022/2026, Rider ou VS Code |
| Outils EF | `dotnet-ef` (déjà installé) |
| Domaine / TLS | Nécessaire pour le VPS |

Si Docker n'est pas installé, deux options :

- installer Docker Desktop ;
- installer PostgreSQL 17 pour Windows et utiliser `Storage:Provider = "FileSystem"` en développement.

---

# 2. Étapes de mise en place

## Étape 0 — Vérifications

```bash
dotnet --version
dotnet ef --version
```

Résultat attendu : `.NET 10.x` et `dotnet-ef 10.x`.

## Étape 1 — Scaffolding du monorepo

Depuis la racine du dépôt :

```bash
mkdir -p backend/src backend/tests
cd backend

dotnet new sln -n Sutura

dotnet new webapi -n Sutura.Api -o src/Sutura.Api --use-controllers
dotnet new classlib -n Sutura.Domain -o src/Sutura.Domain
dotnet new classlib -n Sutura.Application -o src/Sutura.Application
dotnet new classlib -n Sutura.Infrastructure -o src/Sutura.Infrastructure
dotnet new xunit -n Sutura.Tests -o tests/Sutura.Tests

dotnet sln add src/Sutura.Api src/Sutura.Domain src/Sutura.Application src/Sutura.Infrastructure tests/Sutura.Tests

dotnet add src/Sutura.Application reference src/Sutura.Domain
dotnet add src/Sutura.Infrastructure reference src/Sutura.Application src/Sutura.Domain
dotnet add src/Sutura.Api reference src/Sutura.Application src/Sutura.Infrastructure
dotnet add tests/Sutura.Tests reference src/Sutura.Api
```

## Étape 2 — Packages NuGet

```bash
dotnet add src/Sutura.Infrastructure package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add src/Sutura.Infrastructure package Microsoft.EntityFrameworkCore.Design
dotnet add src/Sutura.Infrastructure package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add src/Sutura.Infrastructure package AWSSDK.S3

dotnet add src/Sutura.Api package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add src/Sutura.Api package Swashbuckle.AspNetCore
dotnet add src/Sutura.Api package AspNetCore.HealthChecks.NpgSql

dotnet add tests/Sutura.Tests package Microsoft.AspNetCore.Mvc.Testing
dotnet add tests/Sutura.Tests package Testcontainers.PostgreSql
dotnet add tests/Sutura.Tests package FluentAssertions
```

## Étape 3 — Structure des dossiers

```text
backend/
├── Sutura.sln
├── src/
│   ├── Sutura.Api/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   ├── Program.cs
│   │   └── appsettings.json
│   ├── Sutura.Application/
│   │   ├── DTOs/
│   │   ├── Mapping/
│   │   ├── Services/
│   │   └── Abstractions/
│   ├── Sutura.Domain/
│   │   ├── Entities/
│   │   ├── Enums/
│   │   └── Rules/
│   └── Sutura.Infrastructure/
│       ├── Persistence/
│       ├── Configurations/
│       ├── Migrations/
│       ├── Identity/
│       ├── Auth/
│       └── Storage/
└── tests/
    └── Sutura.Tests/
```

## Étape 4 — Configuration de `Program.cs`

À configurer :

- contrôleurs + `ProblemDetails` ;
- Swagger avec sécurité Bearer JWT ;
- EF Core + Npgsql ;
- Identity ;
- JWT Bearer ;
- CORS ;
- rate limiting ;
- health checks `/health` ;
- seed éventuel des catégories et mesures par défaut.

## Étape 5 — Domaine

Créer les fichiers de la section 3.

## Étape 6 — Infrastructure EF Core

Créer :

- `SuturaDbContext` ;
- configurations par entité ;
- séquence `sync_version_seq` ;
- intercepteur `SyncVersionInterceptor` ;
- `CurrentUserService` ;
- migration initiale.

```bash
dotnet ef migrations add InitialCreate \
  --project src/Sutura.Infrastructure \
  --startup-project src/Sutura.Api

dotnet ef database update \
  --project src/Sutura.Infrastructure \
  --startup-project src/Sutura.Api
```

## Étape 7 — Authentification

- Configurer Identity avec `ApplicationUser`.
- Politique de mot de passe : 8 caractères minimum, majuscule, minuscule, chiffre.
- Implémenter `TokenService` : access token JWT 15 min + refresh token rotatif 30 jours.
- Stocker uniquement le **hash SHA-256** du refresh token.
- Endpoints `AuthController` et `MeController`.
- Rate limiting sur `register`, `login`, `refresh`.
- `CurrentUserService` lit l'utilisateur depuis le JWT.

## Étape 8 — CRUD métier

- DTOs de la section 5.
- Mappings manuels dans `Sutura.Application/Mapping`.
- Services : `ClientService`, `MeasurementService`, `GarmentModelService`, `OrderService`, `PaymentService`.
- Contrôleurs correspondants.
- Vérification systématique de `OwnerId`.
- Suppressions logiques via `DeletedAt` ; archivage via `IsArchived`.

## Étape 9 — Synchronisation

- `SyncService.PushAsync` : LWW + tombstones.
- `SyncService.PullAsync` : curseur `sync_version`.
- `SyncController`.
- Limite de 500 changements par push.
- Idempotence par `(entity, id, updatedAt)`.
- Tests de conflit et d'isolation.

## Étape 10 — Médias

- `IObjectStorage` :
  - `S3ObjectStorage` : AWS, R2, B2, MinIO ;
  - `FileSystemObjectStorage` : développement local.
- `MediaService` : validation MIME réelle, taille max 10 Mo, hash SHA-256.
- `MediaController` : upload, lecture via URL signée, suppression logique.
- Les chemins locaux de l'app ne sont jamais stockés côté serveur.

## Étape 11 — Finitions

- `DashboardController`.
- `ProblemDetails` global.
- Logs structurés.
- CORS.
- Swagger commenté avec XML docs.
- README backend.
- `.env.example`.

## Étape 12 — Tests

```bash
dotnet test
dotnet format --verify-no-changes
```

## Étape 13 — Déploiement VPS

- `Dockerfile` multi-stage.
- `docker-compose.prod.yml` : API + PostgreSQL + MinIO/stockage cloud.
- Ou `systemd` + Kestrel + Nginx + certbot.
- Bundle de migration :

```bash
dotnet ef migrations bundle \
  --project src/Sutura.Infrastructure \
  --startup-project src/Sutura.Api \
  -o migrate
```

---

# 3. Modèles du domaine

## 3.1 `SyncEntity` — base de synchronisation

```csharp
// Sutura.Domain/Entities/SyncEntity.cs
namespace Sutura.Domain.Entities;

public abstract class SyncEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
    public long SyncVersion { get; set; }
}
```

## 3.2 `Client`

```csharp
// Sutura.Domain/Entities/Client.cs
namespace Sutura.Domain.Entities;

public sealed class Client : SyncEntity
{
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Notes { get; set; }
    public bool IsArchived { get; set; }

    public ICollection<MeasurementSet> MeasurementSets { get; set; } = [];
    public ICollection<Order> Orders { get; set; } = [];
}
```

## 3.3 `MeasurementSet` et `Measurement`

```csharp
// Sutura.Domain/Entities/MeasurementSet.cs
namespace Sutura.Domain.Entities;

public sealed class MeasurementSet : SyncEntity
{
    public Guid ClientId { get; set; }
    public Client Client { get; set; } = null!;
    public string GarmentType { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public DateTimeOffset MeasuredAt { get; set; }

    public ICollection<Measurement> Measurements { get; set; } = [];
    public ICollection<Order> Orders { get; set; } = [];
}

public sealed class Measurement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MeasurementSetId { get; set; }
    public MeasurementSet MeasurementSet { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public double Value { get; set; }
    public string Unit { get; set; } = "cm";
}
```

## 3.4 `GarmentModel`

```csharp
// Sutura.Domain/Entities/GarmentModel.cs
namespace Sutura.Domain.Entities;

public sealed class GarmentModel : SyncEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Description { get; set; }
    public Guid? PhotoMediaId { get; set; }
    public MediaAsset? PhotoMedia { get; set; }
    public bool IsArchived { get; set; }

    public ICollection<Order> Orders { get; set; } = [];
}
```

## 3.5 `Order`

```csharp
// Sutura.Domain/Entities/Order.cs
using Sutura.Domain.Enums;

namespace Sutura.Domain.Entities;

public sealed class Order : SyncEntity
{
    public Guid ClientId { get; set; }
    public Client Client { get; set; } = null!;

    public Guid? GarmentModelId { get; set; }
    public GarmentModel? GarmentModel { get; set; }
    public string? ModelNameSnapshot { get; set; }
    public Guid? ModelImageMediaId { get; set; }
    public MediaAsset? ModelImageMedia { get; set; }

    public Guid? MeasurementSetId { get; set; }
    public MeasurementSet? MeasurementSet { get; set; }

    public string? Description { get; set; }
    public int Quantity { get; set; } = 1;
    public long TotalPrice { get; set; }
    public DateTimeOffset DeliveryAt { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.ToStart;
    public string? Notes { get; set; }

    public ICollection<Payment> Payments { get; set; } = [];
}
```

## 3.6 `Payment`

```csharp
// Sutura.Domain/Entities/Payment.cs
using Sutura.Domain.Enums;

namespace Sutura.Domain.Entities;

public sealed class Payment : SyncEntity
{
    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public long Amount { get; set; }
    public DateTimeOffset PaidAt { get; set; }
    public PaymentMethod? Method { get; set; }
    public string? Note { get; set; }
}
```

## 3.7 `MediaAsset`

```csharp
// Sutura.Domain/Entities/MediaAsset.cs
namespace Sutura.Domain.Entities;

public sealed class MediaAsset : SyncEntity
{
    public string ObjectKey { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public string Sha256 { get; set; } = string.Empty;
}
```

## 3.8 Enums

```csharp
// Sutura.Domain/Enums/OrderStatus.cs
namespace Sutura.Domain.Enums;

public enum OrderStatus
{
    ToStart,
    InProgress,
    Ready,
    Delivered,
    Cancelled
}

public static class OrderStatusValues
{
    public const string ToStart = "to_start";
    public const string InProgress = "in_progress";
    public const string Ready = "ready";
    public const string Delivered = "delivered";
    public const string Cancelled = "cancelled";

    public static readonly string[] All =
        [ToStart, InProgress, Ready, Delivered, Cancelled];

    public static string ToValue(this OrderStatus status) => status switch
    {
        OrderStatus.ToStart => ToStart,
        OrderStatus.InProgress => InProgress,
        OrderStatus.Ready => Ready,
        OrderStatus.Delivered => Delivered,
        OrderStatus.Cancelled => Cancelled,
        _ => throw new ArgumentOutOfRangeException(nameof(status))
    };

    public static OrderStatus? Parse(string? value) => value switch
    {
        ToStart => OrderStatus.ToStart,
        InProgress => OrderStatus.InProgress,
        Ready => OrderStatus.Ready,
        Delivered => OrderStatus.Delivered,
        Cancelled => OrderStatus.Cancelled,
        _ => null
    };
}
```

```csharp
// Sutura.Domain/Enums/PaymentMethod.cs
namespace Sutura.Domain.Enums;

public enum PaymentMethod
{
    Cash,
    Transfer,
    Other
}

public static class PaymentMethodValues
{
    public const string Cash = "cash";
    public const string Transfer = "transfer";
    public const string Other = "other";

    public static readonly string[] All = [Cash, Transfer, Other];

    public static string? ToValue(this PaymentMethod? method) => method switch
    {
        PaymentMethod.Cash => Cash,
        PaymentMethod.Transfer => Transfer,
        PaymentMethod.Other => Other,
        _ => null
    };

    public static PaymentMethod? Parse(string? value) => value switch
    {
        Cash => PaymentMethod.Cash,
        Transfer => PaymentMethod.Transfer,
        Other => PaymentMethod.Other,
        _ => null
    };
}
```

## 3.9 Règles métier

```csharp
// Sutura.Domain/Rules/OrderRules.cs
using Sutura.Domain.Enums;

namespace Sutura.Domain.Rules;

public readonly record struct OrderBalance(long TotalPrice, long TotalPaid)
{
    public long Remaining => TotalPrice - TotalPaid;
    public bool IsOverpaid => TotalPaid > TotalPrice;
    public long OverpaidAmount => IsOverpaid ? TotalPaid - TotalPrice : 0;
}

public static class OrderRules
{
    public static bool IsLate(
        OrderStatus status,
        DateTimeOffset deliveryAt,
        DateTimeOffset now) =>
        status is not OrderStatus.Delivered
        and not OrderStatus.Cancelled
        && deliveryAt < now;
}
```

---

# 4. Entités d'authentification

```csharp
// Sutura.Infrastructure/Identity/ApplicationUser.cs
using Microsoft.AspNetCore.Identity;

namespace Sutura.Infrastructure.Identity;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public string FullName { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<Device> Devices { get; set; } = [];
}
```

```csharp
// Sutura.Infrastructure/Identity/RefreshToken.cs
namespace Sutura.Infrastructure.Identity;

public sealed class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
    public string TokenHash { get; set; } = string.Empty;
    public Guid? DeviceId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? RevokedAt { get; set; }
    public string? ReplacedByTokenHash { get; set; }
}
```

```csharp
// Sutura.Infrastructure/Identity/Device.cs
namespace Sutura.Infrastructure.Identity;

public sealed class Device
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? Platform { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset LastSeenAt { get; set; }
    public long LastSyncCursor { get; set; }
}
```

---

# 5. DTOs

## 5.1 DTOs communs

```csharp
// Sutura.Application/DTOs/Common/PagedResult.cs
namespace Sutura.Application.DTOs.Common;

public sealed record PagedResult<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalCount);
```

## 5.2 Auth et profil

```csharp
// Sutura.Application/DTOs/Auth/AuthDtos.cs
using System.ComponentModel.DataAnnotations;

namespace Sutura.Application.DTOs.Auth;

public sealed class RegisterRequest
{
    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string Password { get; init; } = string.Empty;

    [Required, MaxLength(200)]
    public string FullName { get; init; } = string.Empty;
}

public sealed class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;

    public Guid? DeviceId { get; init; }

    [MaxLength(100)]
    public string? DeviceName { get; init; }

    [MaxLength(50)]
    public string? Platform { get; init; }
}

public sealed class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; init; } = string.Empty;

    public Guid? DeviceId { get; init; }
}

public sealed class LogoutRequest
{
    [Required]
    public string RefreshToken { get; init; } = string.Empty;
}

public sealed class UpdateProfileRequest
{
    [Required, MaxLength(200)]
    public string FullName { get; init; } = string.Empty;

    [EmailAddress, MaxLength(256)]
    public string? Email { get; init; }
}

public sealed class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; init; } = string.Empty;

    [Required, MinLength(8), MaxLength(128)]
    public string NewPassword { get; init; } = string.Empty;
}

public sealed record UserDto(
    Guid Id,
    string Email,
    string FullName,
    DateTimeOffset CreatedAt);

public sealed record AuthResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresInSeconds,
    UserDto User);
```

## 5.3 Clients

```csharp
// Sutura.Application/DTOs/Clients/ClientDtos.cs
using System.ComponentModel.DataAnnotations;

namespace Sutura.Application.DTOs.Clients;

public sealed record ClientDto(
    Guid Id,
    string FullName,
    string? Phone,
    string? Notes,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    long SyncVersion);

public sealed record ClientListItemDto(
    Guid Id,
    string FullName,
    string? Phone,
    bool IsArchived,
    DateTimeOffset UpdatedAt);

public sealed class CreateClientRequest
{
    public Guid? Id { get; init; }

    [Required, MaxLength(200)]
    public string FullName { get; init; } = string.Empty;

    [MaxLength(50)]
    public string? Phone { get; init; }

    [MaxLength(2000)]
    public string? Notes { get; init; }
}

public sealed class UpdateClientRequest
{
    [Required, MaxLength(200)]
    public string FullName { get; init; } = string.Empty;

    [MaxLength(50)]
    public string? Phone { get; init; }

    [MaxLength(2000)]
    public string? Notes { get; init; }
}

public sealed class ClientQuery
{
    [MaxLength(100)]
    public string? Search { get; init; }

    public bool IncludeArchived { get; init; }
}
```

## 5.4 Mensurations

```csharp
// Sutura.Application/DTOs/Measurements/MeasurementDtos.cs
using System.ComponentModel.DataAnnotations;

namespace Sutura.Application.DTOs.Measurements;

public sealed record MeasurementDto(
    Guid Id,
    string Name,
    double Value,
    string Unit);

public sealed record MeasurementSetDto(
    Guid Id,
    Guid ClientId,
    string GarmentType,
    string? Notes,
    DateTimeOffset MeasuredAt,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    long SyncVersion,
    IReadOnlyList<MeasurementDto> Measurements);

public sealed record MeasurementSetSummaryDto(
    Guid Id,
    Guid ClientId,
    string GarmentType,
    DateTimeOffset MeasuredAt,
    DateTimeOffset UpdatedAt,
    int MeasurementCount);

public sealed class MeasurementInput
{
    [Required, MaxLength(100)]
    public string Name { get; init; } = string.Empty;

    [Range(0.01, 10000)]
    public double Value { get; init; }

    [Required, MaxLength(10)]
    public string Unit { get; init; } = "cm";
}

public sealed class CreateMeasurementSetRequest : IValidatableObject
{
    public Guid? Id { get; init; }

    [Required]
    public Guid ClientId { get; init; }

    [Required, MaxLength(100)]
    public string GarmentType { get; init; } = string.Empty;

    [MaxLength(2000)]
    public string? Notes { get; init; }

    [Required]
    public DateTimeOffset? MeasuredAt { get; init; }

    [Required]
    public List<MeasurementInput> Measurements { get; init; } = [];

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Measurements.Count == 0)
        {
            yield return new ValidationResult(
                "Au moins une mesure est requise.",
                [nameof(Measurements)]);
        }

        var duplicates = Measurements
            .Select(m => m.Name.Trim().ToLowerInvariant())
            .GroupBy(n => n)
            .Any(g => g.Count() > 1);

        if (duplicates)
        {
            yield return new ValidationResult(
                "Les noms de mesures doivent être uniques.",
                [nameof(Measurements)]);
        }
    }
}
```

## 5.5 Modèles de vêtements

```csharp
// Sutura.Application/DTOs/GarmentModels/GarmentModelDtos.cs
using System.ComponentModel.DataAnnotations;

namespace Sutura.Application.DTOs.GarmentModels;

public sealed record GarmentModelDto(
    Guid Id,
    string Name,
    string? Category,
    string? Description,
    Guid? PhotoMediaId,
    string? PhotoUrl,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    long SyncVersion);

public sealed record GarmentModelListItemDto(
    Guid Id,
    string Name,
    string? Category,
    Guid? PhotoMediaId,
    string? PhotoUrl,
    bool IsArchived,
    DateTimeOffset UpdatedAt);

public sealed class CreateGarmentModelRequest
{
    public Guid? Id { get; init; }

    [Required, MaxLength(200)]
    public string Name { get; init; } = string.Empty;

    [MaxLength(100)]
    public string? Category { get; init; }

    [MaxLength(2000)]
    public string? Description { get; init; }

    public Guid? PhotoMediaId { get; init; }
}

public sealed class UpdateGarmentModelRequest
{
    [Required, MaxLength(200)]
    public string Name { get; init; } = string.Empty;

    [MaxLength(100)]
    public string? Category { get; init; }

    [MaxLength(2000)]
    public string? Description { get; init; }

    public Guid? PhotoMediaId { get; init; }
}

public sealed class GarmentModelQuery
{
    [MaxLength(100)]
    public string? Search { get; init; }

    [MaxLength(100)]
    public string? Category { get; init; }

    public bool IncludeArchived { get; init; }
}
```

## 5.6 Commandes

```csharp
// Sutura.Application/DTOs/Orders/OrderDtos.cs
using System.ComponentModel.DataAnnotations;
using Sutura.Application.DTOs.Payments;

namespace Sutura.Application.DTOs.Orders;

public sealed record OrderDto(
    Guid Id,
    Guid ClientId,
    Guid? GarmentModelId,
    string? ModelNameSnapshot,
    Guid? ModelImageMediaId,
    Guid? MeasurementSetId,
    string? Description,
    int Quantity,
    long TotalPrice,
    DateTimeOffset DeliveryAt,
    string Status,
    string? Notes,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    long SyncVersion,
    bool IsLate);

public sealed record OrderListItemDto(
    Guid Id,
    Guid ClientId,
    string ClientName,
    string? Description,
    DateTimeOffset DeliveryAt,
    string Status,
    long TotalPrice,
    long TotalPaid,
    long Remaining,
    bool IsLate);

public sealed record OrderDetailDto(
    OrderDto Order,
    IReadOnlyList<PaymentDto> Payments,
    BalanceDto Balance);

public sealed class CreateOrderRequest
{
    public Guid? Id { get; init; }

    [Required]
    public Guid ClientId { get; init; }

    public Guid? GarmentModelId { get; init; }

    [MaxLength(200)]
    public string? ModelNameSnapshot { get; init; }

    public Guid? ModelImageMediaId { get; init; }
    public Guid? MeasurementSetId { get; init; }

    [MaxLength(2000)]
    public string? Description { get; init; }

    [Range(1, int.MaxValue)]
    public int Quantity { get; init; } = 1;

    [Range(0, long.MaxValue)]
    public long TotalPrice { get; init; }

    [Required]
    public DateTimeOffset? DeliveryAt { get; init; }

    public string? Status { get; init; }

    [MaxLength(2000)]
    public string? Notes { get; init; }
}

public sealed class UpdateOrderRequest
{
    public Guid? GarmentModelId { get; init; }

    [MaxLength(200)]
    public string? ModelNameSnapshot { get; init; }

    public Guid? ModelImageMediaId { get; init; }
    public Guid? MeasurementSetId { get; init; }

    [MaxLength(2000)]
    public string? Description { get; init; }

    [Range(1, int.MaxValue)]
    public int Quantity { get; init; } = 1;

    [Range(0, long.MaxValue)]
    public long TotalPrice { get; init; }

    [Required]
    public DateTimeOffset? DeliveryAt { get; init; }

    [MaxLength(2000)]
    public string? Notes { get; init; }
}

public sealed class UpdateOrderStatusRequest
{
    [Required]
    public string Status { get; init; } = string.Empty;
}

public sealed class OrderQuery
{
    public Guid? ClientId { get; init; }
    public string? Status { get; init; }
    public bool OnlyLate { get; init; }
    public bool OnlyUpcoming { get; init; }
}
```

## 5.7 Paiements

```csharp
// Sutura.Application/DTOs/Payments/PaymentDtos.cs
using System.ComponentModel.DataAnnotations;

namespace Sutura.Application.DTOs.Payments;

public sealed record PaymentDto(
    Guid Id,
    Guid OrderId,
    long Amount,
    DateTimeOffset PaidAt,
    string? Method,
    string? Note,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    long SyncVersion);

public sealed class CreatePaymentRequest
{
    public Guid? Id { get; init; }

    [Range(1, long.MaxValue)]
    public long Amount { get; init; }

    [Required]
    public DateTimeOffset? PaidAt { get; init; }

    public string? Method { get; init; }

    [MaxLength(2000)]
    public string? Note { get; init; }
}

public sealed record BalanceDto(
    Guid OrderId,
    long TotalPrice,
    long TotalPaid,
    long Remaining,
    bool IsOverpaid,
    long OverpaidAmount);
```

## 5.8 Tableau de bord

```csharp
// Sutura.Application/DTOs/Dashboard/DashboardDtos.cs
namespace Sutura.Application.DTOs.Dashboard;

public sealed record DashboardSummaryDto(
    int ActiveOrders,
    int LateOrders,
    int UpcomingOrders,
    long OutstandingAmount);
```

## 5.9 Médias

```csharp
// Sutura.Application/DTOs/Media/MediaDtos.cs
namespace Sutura.Application.DTOs.Media;

public sealed record MediaDto(
    Guid Id,
    string Url,
    string ContentType,
    long SizeBytes,
    DateTimeOffset CreatedAt);

public sealed record MediaUploadResponse(
    Guid Id,
    string Url,
    string ContentType,
    long SizeBytes);
```

## 5.10 Synchronisation

```csharp
// Sutura.Application/DTOs/Sync/SyncDtos.cs
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Sutura.Application.DTOs.Clients;
using Sutura.Application.DTOs.GarmentModels;
using Sutura.Application.DTOs.Measurements;
using Sutura.Application.DTOs.Orders;
using Sutura.Application.DTOs.Payments;

namespace Sutura.Application.DTOs.Sync;

public enum SyncEntityType
{
    Client,
    MeasurementSet,
    GarmentModel,
    Order,
    Payment
}

public enum SyncChangeStatus
{
    Applied,
    Conflict,
    Invalid
}

public sealed class SyncPushRequest : IValidatableObject
{
    [Required]
    public Guid DeviceId { get; init; }

    [Required]
    public List<SyncChange> Changes { get; init; } = [];

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Changes.Count is < 1 or > 500)
        {
            yield return new ValidationResult(
                "Le lot doit contenir entre 1 et 500 changements.",
                [nameof(Changes)]);
        }
    }
}

public sealed class SyncChange
{
    [Required]
    public SyncEntityType Entity { get; init; }

    [Required]
    public Guid Id { get; init; }

    [Required]
    public DateTimeOffset? UpdatedAt { get; init; }

    public bool Deleted { get; init; }

    /// <summary>
    /// Payload attendu selon Entity :
    /// Client = CreateClientRequest,
    /// MeasurementSet = CreateMeasurementSetRequest,
    /// GarmentModel = CreateGarmentModelRequest,
    /// Order = CreateOrderRequest,
    /// Payment = CreatePaymentRequest.
    /// Null si Deleted = true.
    /// </summary>
    public JsonElement? Data { get; init; }
}

public sealed record SyncChangeResult(
    SyncEntityType Entity,
    Guid Id,
    SyncChangeStatus Status,
    string? Message,
    JsonElement? ServerData);

public sealed record SyncPushResponse(
    long NextCursor,
    DateTimeOffset ServerTime,
    IReadOnlyList<SyncChangeResult> Results);

public sealed record DeletedEntityDto(
    SyncEntityType Entity,
    Guid Id,
    DateTimeOffset DeletedAt,
    long SyncVersion);

public sealed record SyncPullResponse(
    long Cursor,
    bool HasMore,
    DateTimeOffset ServerTime,
    IReadOnlyList<ClientDto> Clients,
    IReadOnlyList<MeasurementSetDto> MeasurementSets,
    IReadOnlyList<GarmentModelDto> GarmentModels,
    IReadOnlyList<OrderDto> Orders,
    IReadOnlyList<PaymentDto> Payments,
    IReadOnlyList<DeletedEntityDto> Deleted);
```

---

# 6. Règles métier et validation

## 6.1 DataAnnotations

- Requis : email, mot de passe, noms, identifiants, dates.
- Longueurs maximales : noms 200, notes 2000, téléphone 50.
- Montants : prix total ≥ 0, paiement strictement > 0.
- Quantité : ≥ 1.
- Mesures : valeur > 0, unité renseignée, noms uniques.
- Batch de sync : 1 à 500 changements.

## 6.2 Validations dans les services

| Règle | Service |
|---|---|
| Le client appartient au compte | OrderService, MeasurementService |
| Le modèle appartient au compte | OrderService, GarmentModelService |
| Le jeu de mesures appartient au compte et au client | OrderService |
| La commande appartient au compte | PaymentService |
| Le média appartient au compte | GarmentModelService, OrderService, MediaService |
| Statut de commande valide | OrderService |
| Méthode de paiement valide | PaymentService |
| Pas de suppression physique d'un client avec commandes | ClientService |
| Solde calculé, jamais stocké | PaymentService, OrderService |
| Retard calculé, jamais stocké | OrderService, DashboardService |
| LWW : `incoming.UpdatedAt` comparé à `server.UpdatedAt` | SyncService |
| Tie-break par `DeviceId` si dates égales | SyncService |
| Mise à jour de `SyncVersion` à chaque écriture | SyncVersionInterceptor |

---

# 7. Configurations EF Core

## 7.1 DbContext

`SuturaDbContext` doit contenir :

```csharp
DbSet<Client> Clients
DbSet<MeasurementSet> MeasurementSets
DbSet<Measurement> Measurements
DbSet<GarmentModel> GarmentModels
DbSet<Order> Orders
DbSet<Payment> Payments
DbSet<MediaAsset> MediaAssets
DbSet<RefreshToken> RefreshTokens
DbSet<Device> Devices
```

Identity : `IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>`.

## 7.2 Configurations à créer

- `SyncEntityConfiguration<T>` : clé, `Id` non généré, `OwnerId`, timestamps, `SyncVersion`, index `(OwnerId, SyncVersion)`.
- `ClientConfiguration`
- `MeasurementSetConfiguration`
- `MeasurementConfiguration`
- `GarmentModelConfiguration`
- `OrderConfiguration`
- `PaymentConfiguration`
- `MediaAssetConfiguration`
- `ApplicationUserConfiguration`
- `RefreshTokenConfiguration`
- `DeviceConfiguration`

## 7.3 Points importants

- Tables en `snake_case`.
- `Id` : `ValueGeneratedNever()`.
- `TotalPrice`, `Amount` : `bigint`.
- `Measurement.Value` : `double precision`.
- `Order.Status` : conversion string via `OrderStatusValues.ToValue` / `Parse`.
- `Payment.Method` : conversion string via `PaymentMethodValues`.
- Index :
  - `(OwnerId, SyncVersion)` ;
  - `(OwnerId, UpdatedAt)` ;
  - `(ClientId)` sur `orders` et `measurement_sets` ;
  - `(OrderId)` sur `payments` ;
  - `(DeliveryAt)` et `(Status)` sur `orders` ;
  - unique sur `media_assets.ObjectKey` ;
  - unique sur `refresh_tokens.TokenHash`.
- Filtre global : `DeletedAt == null && OwnerId == currentUser`.
- Sync : `IgnoreQueryFilters()`.
- Suppression logique uniquement.
- Séquence PostgreSQL `sync_version_seq` + intercepteur.

---

# 8. Contrôleurs, services et endpoints

## 8.1 Contrôleurs

- `AuthController`
- `MeController`
- `ClientsController`
- `MeasurementSetsController`
- `GarmentModelsController`
- `OrdersController`
- `PaymentsController`
- `DashboardController`
- `SyncController`
- `MediaController`

## 8.2 Services

- `AuthService`
- `TokenService`
- `UserService`
- `ClientService`
- `MeasurementService`
- `GarmentModelService`
- `OrderService`
- `PaymentService`
- `DashboardService`
- `MediaService`
- `SyncService`
- `CurrentUserService`
- `SyncVersionProvider`
- `MediaUrlResolver`

## 8.3 Stockage

- `IObjectStorage`
- `S3ObjectStorage`
- `FileSystemObjectStorage`
- Configuration `Storage:Provider = S3 | FileSystem`.

## 8.4 Endpoints

| Méthode | Route | Rôle |
|---|---|---|
| POST | `/api/v1/auth/register` | Inscription |
| POST | `/api/v1/auth/login` | Connexion |
| POST | `/api/v1/auth/refresh` | Renouvellement |
| POST | `/api/v1/auth/logout` | Déconnexion |
| GET | `/api/v1/me` | Profil |
| PUT | `/api/v1/me` | Modifier profil |
| POST | `/api/v1/me/password` | Changer mot de passe |
| GET | `/api/v1/clients` | Liste + recherche |
| GET | `/api/v1/clients/{id}` | Détail |
| POST | `/api/v1/clients` | Création |
| PUT | `/api/v1/clients/{id}` | Modification |
| POST | `/api/v1/clients/{id}/archive` | Archiver |
| GET | `/api/v1/clients/{id}/measurement-sets` | Liste |
| POST | `/api/v1/clients/{id}/measurement-sets` | Création |
| GET | `/api/v1/measurement-sets/{id}` | Détail |
| DELETE | `/api/v1/measurement-sets/{id}` | Suppression logique |
| GET | `/api/v1/garment-models` | Liste + filtres |
| GET | `/api/v1/garment-models/{id}` | Détail |
| POST | `/api/v1/garment-models` | Création |
| PUT | `/api/v1/garment-models/{id}` | Modification |
| POST | `/api/v1/garment-models/{id}/archive` | Archiver |
| GET | `/api/v1/orders` | Liste + filtres |
| GET | `/api/v1/orders/{id}` | Détail + paiements + solde |
| POST | `/api/v1/orders` | Création |
| PUT | `/api/v1/orders/{id}` | Modification |
| PATCH | `/api/v1/orders/{id}/status` | Changer statut |
| GET | `/api/v1/orders/{id}/payments` | Paiements |
| POST | `/api/v1/orders/{id}/payments` | Ajouter paiement |
| DELETE | `/api/v1/orders/{id}/payments/{paymentId}` | Supprimer paiement |
| GET | `/api/v1/orders/{id}/balance` | Solde |
| GET | `/api/v1/dashboard/summary` | Indicateurs |
| POST | `/api/v1/sync/push` | Envoyer changements |
| GET | `/api/v1/sync/changes` | Récupérer changements |
| POST | `/api/v1/media` | Upload photo |
| GET | `/api/v1/media/{id}` | URL signée |
| DELETE | `/api/v1/media/{id}` | Suppression logique |
| GET | `/health` | Santé API + DB |

---

# 9. Tests

## 9.1 Unitaires

- `OrderBalance.Remaining`
- `OrderBalance.IsOverpaid`
- `OrderBalance.OverpaidAmount`
- `OrderRules.IsLate`
- Parsing des statuts et méthodes de paiement
- LWW et tie-break

## 9.2 Intégration

- Register / login / refresh / logout
- Isolation entre comptes A et B
- CRUD clients, mesures, modèles, commandes, paiements
- Validation des payloads invalides
- Push / pull de sync
- Tombstones
- Conflits LWW
- Upload média avec stockage factice
- Pagination du flux de sync

## 9.3 Commandes

```bash
dotnet test
dotnet format --verify-no-changes
```

---

# 10. Déploiement VPS

## 10.1 Docker

- `Dockerfile` multi-stage.
- `docker-compose.prod.yml` :
  - `api` ;
  - `postgres` ;
  - `minio` ou stockage cloud externe.

## 10.2 systemd + Nginx

- Service `sutura-api.service`.
- Kestrel sur `127.0.0.1:5000`.
- Nginx reverse proxy HTTPS.
- certbot pour le certificat.
- Variables d'environnement dans `/etc/sutura/api.env`.

## 10.3 Migrations

```bash
dotnet ef migrations bundle \
  --project src/Sutura.Infrastructure \
  --startup-project src/Sutura.Api \
  -o migrate

./migrate --connection "Host=...;Database=sutura;Username=...;Password=..."
```

## 10.4 Configuration de production

```json
{
  "ConnectionStrings": {
    "Default": "Host=...;Database=sutura;Username=...;Password=..."
  },
  "Jwt": {
    "Issuer": "https://api.sutura.example",
    "Audience": "sutura-app",
    "Key": "secret-fourni-par-environnement",
    "AccessTokenMinutes": 15,
    "RefreshTokenDays": 30
  },
  "Storage": {
    "Provider": "S3",
    "Endpoint": "https://...",
    "Bucket": "sutura-media",
    "Region": "auto"
  }
}
```

Aucun secret dans le dépôt.

---

# 11. Critères d'acceptation

- [ ] L'API démarre et `/swagger` est accessible.
- [ ] Le bouton Authorize JWT fonctionne.
- [ ] Un compte peut s'inscrire, se connecter, se déconnecter.
- [ ] Le refresh token est rotatif et révocable.
- [ ] Deux comptes sont totalement isolés.
- [ ] Les CRUD respectent les règles métier.
- [ ] Les suppressions sont logiques.
- [ ] Le pull de sync renvoie les changements depuis un curseur.
- [ ] Les tombstones sont renvoyées.
- [ ] Le push applique le LWW et signale les conflits.
- [ ] Les photos sont uploadées et accessibles uniquement par leur propriétaire.
- [ ] Les tests passent.
- [ ] Le déploiement VPS est documenté et reproductible.
- [ ] Le contrat API est prêt pour l'intégration Flutter.

---

*Fin du document — Sutura V2 Backend*
