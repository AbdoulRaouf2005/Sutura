# Guide de conception de l'API ASP.NET Core de Sutura

> Guide pratique pour construire progressivement l'API REST de Sutura avec ASP.NET Core MVC, Entity Framework Core, PostgreSQL et Swagger.

## 1. Objectif du backend

Le backend de Sutura fournit une API HTTP destinée principalement à l'application mobile Flutter. Il reçoit des requêtes JSON, applique les règles métier, lit ou modifie PostgreSQL, puis renvoie une réponse JSON.

ASP.NET Core MVC signifie ici que l'application utilise des **contrôleurs** pour recevoir les requêtes HTTP. Il ne s'agit pas de créer des pages HTML Razor : les contrôleurs de Sutura renvoient des données JSON.

Le flux général est le suivant :

```text
Application Flutter
        |
        | HTTP/HTTPS + JSON + JWT
        v
Controller ASP.NET Core
        |
        v
Service ou cas d'utilisation
        |
        v
Entity Framework Core
        |
        v
PostgreSQL
```

Swagger/OpenAPI sert à documenter et tester les endpoints pendant le développement. Il ne remplace ni les contrôleurs ni la base de données.

## 2. Par quel endpoint commencer ?

Il faut distinguer deux débuts.

### 2.1 Premier endpoint technique : le health check

Commencer par un endpoint très simple permet de vérifier que l'application démarre et répond :

```http
GET /health
```

Réponse attendue :

```json
{
  "status": "ok"
}
```

Ce endpoint ne dépend pas encore de PostgreSQL, de l'authentification ou des entités métier. Il valide le serveur HTTP, le routage et le fonctionnement de base de l'application.

### 2.2 Premier endpoint métier : créer un client

Le premier endpoint métier recommandé pour Sutura est :

```http
POST /api/v1/clients
```

Pourquoi commencer par les clients ?

- Un client est une ressource centrale de Sutura.
- Une commande appartient à un client.
- Les mensurations appartiennent à un client.
- Le cas d'utilisation est facile à comprendre et à tester.
- Il permet de valider toute la chaîne : contrôleur, DTO, validation, base de données et réponse HTTP.

Exemple de requête :

```json
{
  "fullName": "Amina Issa",
  "phone": "+22700000000",
  "notes": "Cliente régulière"
}
```

Réponse recommandée : `201 Created` avec l'identifiant de la ressource créée.

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "fullName": "Amina Issa",
  "phone": "+22700000000",
  "notes": "Cliente régulière",
  "createdAt": "2026-11-13T10:00:00Z"
}
```

Le endpoint `POST /api/v1/clients` doit être suivi par :

```text
GET    /api/v1/clients
GET    /api/v1/clients/{id}
PUT    /api/v1/clients/{id}
DELETE /api/v1/clients/{id}
```

La suppression doit normalement être logique : le client est archivé avec `IsArchived = true` plutôt que supprimé définitivement.

## 3. Ordre conseillé pour Sutura

L'ordre suivant respecte les dépendances entre les entités actuelles du projet.

### Étape 0 : vérifier le socle technique

Avant les endpoints métier :

1. Vérifier que le projet cible .NET 10.
2. Vérifier la connexion PostgreSQL.
3. Vérifier que `SuturaDbContext` est enregistré dans `Program.cs`.
4. Appliquer la migration initiale.
5. Ajouter le health check.
6. Ouvrir Swagger et vérifier que l'API démarre.

Commandes utiles :

```bash
dotnet restore
dotnet build
dotnet ef database update
dotnet run
```

### Étape 1 : authentification

Pour l'utilisation réelle avec Flutter, développer ensuite :

```http
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/auth/me
```

Le login doit retourner un JWT. Les endpoints métier doivent ensuite être protégés avec `[Authorize]`.

Important : les entités métier devront être liées à l'utilisateur authentifié, par exemple avec une propriété `UserId`. Le serveur doit prendre cet utilisateur depuis le JWT et non depuis le JSON envoyé par le client.

### Étape 2 : clients

Développer le CRUD des clients :

```http
GET    /api/v1/clients
POST   /api/v1/clients
GET    /api/v1/clients/{id}
PUT    /api/v1/clients/{id}
DELETE /api/v1/clients/{id}
```

C'est la première fonctionnalité complète à stabiliser dans Swagger.

### Étape 3 : mensurations

Une fois un client créé, ajouter ses jeux de mensurations :

```http
GET  /api/v1/clients/{clientId}/measurement-sets
POST /api/v1/clients/{clientId}/measurement-sets
GET  /api/v1/measurement-sets/{id}
PUT  /api/v1/measurement-sets/{id}
```

Un `MeasurementSet` appartient à un `Client` et contient plusieurs `Measurement`. Il est préférable de créer et valider le jeu de mensurations avant de créer une commande.

### Étape 4 : modèles de vêtements

Ajouter le catalogue des modèles :

```http
GET    /api/v1/garment-models
POST   /api/v1/garment-models
GET    /api/v1/garment-models/{id}
PUT    /api/v1/garment-models/{id}
DELETE /api/v1/garment-models/{id}
```

Les images et l'intégration Google Drive peuvent être ajoutées après la gestion de base des modèles. Il faut d'abord stabiliser les données relationnelles.

### Étape 5 : commandes

La commande vient après les clients, les mensurations et les modèles :

```http
GET   /api/v1/orders
POST  /api/v1/orders
GET   /api/v1/orders/{id}
PUT   /api/v1/orders/{id}
PATCH /api/v1/orders/{id}/status
```

Lors de `POST /api/v1/orders`, le serveur doit vérifier :

- que le client existe et appartient à l'utilisateur connecté ;
- que le modèle existe s'il est fourni ;
- que le jeu de mensurations existe s'il est fourni ;
- que le prix et la date de livraison sont valides ;
- que le statut initial est autorisé.

Une commande doit conserver les informations importantes au moment de sa création. Par exemple, si le nom du modèle change plus tard, l'historique de la commande ne doit pas devenir incohérent.

### Étape 6 : paiements

Les paiements peuvent être ajoutés après les commandes :

```http
GET  /api/v1/orders/{orderId}/payments
POST /api/v1/orders/{orderId}/payments
```

Cette fonctionnalité doit gérer les acomptes, les paiements partiels et le total déjà payé. Elle ne doit pas être mélangée au premier CRUD des commandes.

## 4. Structure d'un endpoint MVC

Pour chaque ressource, suivre cette chaîne :

```text
Route HTTP
   -> Controller
   -> Request DTO
   -> Validation
   -> Service ou cas d'utilisation
   -> DbContext / repository
   -> Response DTO
```

Exemple d'organisation :

```text
Api/Controllers/ClientsController.cs
Application/DTOs/Clients/CreateClientRequest.cs
Application/DTOs/Clients/ClientResponse.cs
Application/Interfaces/IClientService.cs
Application/Mapping/ClientMapping.cs
Domain/Entities/Client.cs
Infrastructure/Data/SuturaDbContext.cs
```

### Responsabilité du contrôleur

Le contrôleur doit rester mince. Il doit :

- lire les paramètres de la requête ;
- appeler le service ;
- retourner le bon code HTTP ;
- laisser la logique métier au service ou au domaine.

Il ne doit pas contenir toutes les requêtes EF Core ni toutes les règles métier.

### DTO de requête et de réponse

Ne pas exposer directement les entités EF Core dans les endpoints. Utiliser des DTO distincts :

- `CreateClientRequest` pour les données reçues ;
- `UpdateClientRequest` pour la modification ;
- `ClientResponse` pour les données retournées.

Cela évite qu'un client puisse modifier des propriétés contrôlées par le serveur comme `Id`, `CreatedAt` ou `IsArchived`.

## 5. Règles HTTP à appliquer

| Situation                 |         Code HTTP conseillé |
| ------------------------- | --------------------------: |
| Lecture réussie           |                    `200 OK` |
| Création réussie          |               `201 Created` |
| Modification sans contenu |            `204 No Content` |
| Données invalides         |           `400 Bad Request` |
| Utilisateur non connecté  |          `401 Unauthorized` |
| Action interdite          |             `403 Forbidden` |
| Ressource absente         |             `404 Not Found` |
| Conflit métier            |              `409 Conflict` |
| Erreur serveur            | `500 Internal Server Error` |

Pour une création, utiliser `CreatedAtAction` afin de retourner aussi l'URL de la ressource créée.

## 6. Méthode de conception d'un endpoint

Pour chaque nouvel endpoint, suivre ces étapes :

1. Décrire le besoin métier en une phrase.
2. Choisir la ressource et la route REST.
3. Définir la méthode HTTP et les codes de réponse.
4. Créer le DTO de requête.
5. Ajouter les validations.
6. Implémenter le cas d'utilisation ou service.
7. Ajouter ou adapter l'entité et la configuration EF Core.
8. Créer une migration si le schéma change.
9. Implémenter le contrôleur.
10. Tester le cas nominal dans Swagger.
11. Tester les erreurs : données invalides, identifiant inconnu, accès interdit.
12. Ajouter un test automatisé avant de passer à la ressource suivante.

## 7. Tester avec Swagger

Le projet utilise `Swashbuckle.AspNetCore`. En développement :

1. lancer l'application avec `dotnet run` ;
2. ouvrir `https://localhost:<port>/swagger` ;
3. choisir un endpoint ;
4. cliquer sur `Try it out` ;
5. saisir le JSON ;
6. exécuter la requête ;
7. vérifier le code HTTP et le corps de la réponse.

Swagger est excellent pour vérifier rapidement le contrat HTTP. Il ne remplace toutefois pas les tests automatisés, notamment pour l'autorisation et l'accès aux données d'un autre utilisateur.

## 8. Première séquence de test recommandée

La première démonstration complète de Sutura devrait être :

```text
1. GET /health
2. POST /api/v1/auth/register
3. POST /api/v1/auth/login
4. Autoriser Swagger avec le JWT
5. POST /api/v1/clients
6. GET /api/v1/clients
7. GET /api/v1/clients/{id}
8. PUT /api/v1/clients/{id}
9. DELETE /api/v1/clients/{id}
```

Après cette séquence, le socle de l'API est validé. Il est alors logique d'ajouter les mensurations, puis les modèles et enfin les commandes.

## 9. Points de vigilance pour le projet actuel

- Conserver le préfixe `/api/v1` prévu dans la spécification de Sutura.
- Utiliser `Guid` pour les identifiants exposés par l'API.
- Utiliser `DateTimeOffset` et UTC pour les dates dans les nouvelles implémentations.
- Ne pas accepter `UserId` dans le corps d'une requête métier.
- Filtrer chaque requête par l'utilisateur authentifié lorsque l'authentification sera en place.
- Utiliser `ProblemDetails` pour les erreurs.
- Garder Swagger activé en développement, mais le protéger ou le désactiver en production.
- Ne pas intégrer OpenAI ou Google Drive avant que les CRUD principaux soient stables.

## 10. Résumé de la décision

Pour Sutura, l'ordre de conception recommandé est :

```text
Health check
   -> Authentification
   -> Clients
   -> Mensurations
   -> Modèles de vêtements
   -> Commandes
   -> Paiements
   -> Google Drive et sauvegardes
```

Le premier endpoint technique est `GET /health`. Le premier endpoint métier à développer est `POST /api/v1/clients`, car il valide une fonctionnalité centrale sans dépendre de plusieurs autres ressources. Les commandes ne doivent pas être le premier endpoint : elles dépendent déjà des clients et des mensurations.
