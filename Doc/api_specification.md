# Spécification de l'API — Sutura V2

> Contrat REST initial pour le backend ASP.NET Core .NET 10.  
> Préfixe : `/api/v1`. Format : JSON UTF-8. Authentification : Bearer JWT.

## 1. Conventions générales

- Base locale de développement : `https://localhost:<port>/api/v1`.
- Les routes métier nécessitent un JWT valide.
- Les identifiants sont des UUID.
- Les dates/horodatages sont ISO 8601 ; les dates de livraison utilisent `YYYY-MM-DD`.
- Les montants sont des nombres décimaux JSON avec une devise ISO 4217.
- Les listes utilisent `page` et `pageSize` (valeurs par défaut 1 et 20, maximum 100).
- Les erreurs suivent `ProblemDetails` (`type`, `title`, `status`, `detail`, `instance`).
- Ne jamais accepter le propriétaire (`userId`) depuis le corps de la requête.

## 2. Authentification

| Méthode | Route | Description | Accès |
|---|---|---|---|
| POST | `/auth/register` | Créer un compte | Public |
| POST | `/auth/login` | Connexion et émission JWT | Public |
| POST | `/auth/refresh` | Renouveler les jetons | Public avec refresh token |
| POST | `/auth/revoke` | Révoquer le refresh token courant | Authentifié |
| GET | `/auth/me` | Profil du compte connecté | Authentifié |

Exemple `POST /auth/login` :

```json
{
  "email": "couturier@example.com",
  "password": "mot-de-passe"
}
```

Réponse indicative :

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<opaque-refresh-token>",
  "expiresAt": "2026-11-11T20:00:00Z",
  "tokenType": "Bearer"
}
```

Le refresh token doit être aléatoire, stocké sous forme de hash, avec date d'expiration, révocation et rotation. La durée de vie des jetons sera définie dans la configuration.

## 3. Clients

| Méthode | Route | Description |
|---|---|---|
| GET | `/clients` | Liste paginée, recherche par nom/téléphone |
| POST | `/clients` | Créer un client |
| GET | `/clients/{id}` | Détail d'un client |
| PUT | `/clients/{id}` | Modifier un client |
| DELETE | `/clients/{id}` | Archiver le client (suppression logique) |
| GET | `/clients/{id}/measurements` | Consulter ses mensurations |
| PUT | `/clients/{id}/measurements` | Remplacer/mettre à jour ses mensurations |

Exemple de création :

```json
{
  "firstName": "Amina",
  "lastName": "Issa",
  "phoneNumber": "+227XXXXXXXX"
}
```

Mesures :

```json
{
  "measuredAt": "2026-11-11T18:00:00Z",
  "measurements": [
    { "measurementDefinitionId": "00000000-0000-0000-0000-000000000001", "value": 92.5 }
  ]
}
```

Les identifiants et libellés définitifs des mensurations seront fournis par l'API de catalogue. Le serveur valide que les définitions existent et sont actives.

## 4. Catalogue des mensurations

| Méthode | Route | Description |
|---|---|---|
| GET | `/measurement-definitions` | Liste des mensurations actives |
| POST | `/measurement-definitions` | Ajouter une définition personnalisée (à activer si nécessaire) |
| PUT | `/measurement-definitions/{id}` | Modifier une définition appartenant au compte |

Les définitions système sont en lecture seule. Le catalogue initial exact doit être confirmé par le couturier.

## 5. Modèles de vêtements et photos

| Méthode | Route | Description |
|---|---|---|
| GET | `/models` | Liste paginée des modèles |
| POST | `/models` | Créer un modèle |
| GET | `/models/{id}` | Détail d'un modèle |
| PUT | `/models/{id}` | Modifier un modèle |
| DELETE | `/models/{id}` | Archiver un modèle |
| POST | `/models/{id}/photos` | Ajouter une photo |
| PUT | `/models/{id}/photos/{photoId}/primary` | Définir la photo principale |
| DELETE | `/models/{id}/photos/{photoId}` | Supprimer une photo |

Pour l'upload, préférer `multipart/form-data`. L'API vérifie le type MIME réel, l'extension, la taille maximale configurée et le propriétaire du modèle avant d'envoyer le fichier à Google Drive.

La réponse photo renvoie un identifiant interne, le nom, le type, la taille et éventuellement une URL temporaire générée côté serveur. Ne pas enregistrer ni renvoyer de lien Drive public permanent.

## 6. Commandes

| Méthode | Route | Description |
|---|---|---|
| GET | `/orders` | Liste paginée avec filtres |
| POST | `/orders` | Créer une commande |
| GET | `/orders/{id}` | Détail d'une commande |
| PUT | `/orders/{id}` | Modifier les informations |
| PATCH | `/orders/{id}/status` | Changer le statut |
| GET | `/orders/{id}/measurements` | Consulter les mensurations figées |
| GET | `/orders/due-soon` | Commandes à livrer prochainement |

Filtres possibles : `status`, `clientId`, `fromDeliveryDate`, `toDeliveryDate`, `search`, `page`, `pageSize`.

Exemple de création :

```json
{
  "clientId": "11111111-1111-1111-1111-111111111111",
  "clothingModelId": "22222222-2222-2222-2222-222222222222",
  "description": "Tenue sur mesure",
  "price": 25000,
  "currency": "XOF",
  "deliveryDate": "2026-11-25",
  "copyClientMeasurements": true
}
```

À la création, le backend vérifie l'appartenance des ressources au compte, puis copie les mensurations dans `OrderMeasurementSnapshots`. Le modèle peut être nullable uniquement si le métier autorise une commande sans modèle du catalogue.

Statuts proposés : `Pending`, `InProgress`, `Ready`, `Delivered`, `Cancelled`. Le serveur valide les transitions.

## 7. Paiements

Aucun endpoint de paiement n'est inclus dans le MVP initial tant que le fonctionnement réel (acomptes, règlements partiels, méthodes) n'a pas été confirmé. Si la fonctionnalité est validée, ajouter :

- `GET /orders/{id}/payments`
- `POST /orders/{id}/payments`
- `DELETE /orders/{id}/payments/{paymentId}` (annulation logique, jamais effacement silencieux)

## 8. Google Drive et sauvegardes

| Méthode | Route | Description |
|---|---|---|
| GET | `/integrations/google-drive/status` | État de connexion Drive |
| GET | `/integrations/google-drive/authorize` | Démarrer OAuth |
| GET | `/integrations/google-drive/callback` | Callback OAuth |
| POST | `/integrations/google-drive/disconnect` | Déconnecter le compte |
| POST | `/backups` | Déclencher une sauvegarde |
| GET | `/backups` | Historique des sauvegardes |
| GET | `/backups/{id}` | Détail d'une sauvegarde |
| POST | `/backups/{id}/restore` | Restaurer (administration contrôlée) |

La restauration est une opération destructive : exiger une confirmation explicite, vérifier l'intégrité et ne jamais l'exécuter comme une simple requête automatique du mobile.

## 9. Codes HTTP

| Code | Utilisation |
|---|---|
| 200 | Lecture ou modification réussie |
| 201 | Ressource créée, avec `Location` |
| 204 | Suppression logique/déconnexion sans corps |
| 400 | Validation ou transition invalide |
| 401 | Non authentifié |
| 403 | Authentifié mais action interdite |
| 404 | Ressource absente ou n'appartenant pas au compte |
| 409 | Conflit métier (ex. numéro de commande déjà utilisé) |
| 413 | Fichier trop volumineux |
| 415 | Type de fichier non accepté |
| 429 | Limite de requêtes atteinte |
| 500 | Erreur inattendue, sans fuite de détails internes |

## 10. Sécurité et tests

- Authentification et autorisation testées sur chaque contrôleur métier.
- Tests d'accès croisé entre deux comptes.
- Validation serveur de tous les DTO.
- Limitation de taille et validation des fichiers uploadés.
- Aucun secret, stack trace ou token dans les logs.
- Swagger activé en développement ; accès protégé ou désactivé en production selon le déploiement.
- Versionner les routes (`v1`) pour faire évoluer le contrat sans casser Flutter.
