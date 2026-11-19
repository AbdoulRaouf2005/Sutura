# Intégration Google Drive — Sutura V2

> Stratégie initiale : photos des modèles et sauvegardes de la base, dans le Drive personnel du couturier. Les fichiers restent privés.

## 1. Objectifs et limites

Google Drive sert de stockage distant pour :
1. les photos de référence des modèles de vêtements ;
2. les archives de sauvegarde de la base PostgreSQL.

PostgreSQL reste la source de vérité des données métier. Drive ne remplace ni les tables relationnelles ni les migrations.

Le MVP vise un compte personnel et un seul appareil. L'intégration doit néanmoins isoler les fichiers par utilisateur et ne jamais rendre les photos publiques par défaut.

## 2. Organisation Drive proposée

Créer un dossier racine appartenant à l'application, par exemple `Sutura` :

```text
Sutura/
├── ModelPhotos/
│   └── <model-id>/
│       ├── <photo-id>.jpg
│       └── ...
└── Backups/
    ├── sutura-backup-2026-11-11T190000Z.dump
    └── manifest.json
```

Les noms sont générés par l'application (UUID) plutôt que construits à partir du nom du client. Éviter de placer des noms ou numéros de téléphone dans les noms de fichiers.

## 3. Autorisation OAuth

### Scope recommandé

Commencer avec le scope Google Drive `https://www.googleapis.com/auth/drive.file`. Il permet à l'application de créer et gérer les fichiers qu'elle crée ou que l'utilisateur ouvre avec elle, plutôt que d'obtenir un accès global à tout le Drive.

Ne demander aucun scope plus large sans besoin démontré.

### Flux recommandé

1. Le couturier demande la connexion Google Drive depuis Sutura.
2. L'API crée une demande OAuth avec `state` aléatoire et protection CSRF.
3. Le navigateur ouvre la page de consentement Google.
4. Google redirige vers l'URL callback configurée.
5. Le backend vérifie `state`, échange le code contre les jetons et enregistre le refresh token de façon chiffrée.
6. Le backend crée ou retrouve le dossier racine Sutura.
7. L'application peut alors envoyer des photos et des sauvegardes.

Pour une application native, le flux OAuth doit respecter les recommandations Google pour les clients installés. Dans l'architecture retenue, le backend garde les jetons Drive et effectue les appels Drive : ne jamais embarquer un client secret dans Flutter.

### Configuration locale

Placer les paramètres non secrets dans `appsettings.Development.json` et les secrets dans .NET User Secrets ou variables d'environnement :

- `GoogleDrive:ClientId`
- `GoogleDrive:ClientSecret` (secret uniquement côté serveur)
- `GoogleDrive:RedirectUri`
- `GoogleDrive:Scopes`
- `GoogleDrive:RootFolderName`

Ne jamais versionner `ClientSecret`, refresh token, clé de chiffrement ou fichier de credentials.

## 4. Composants à développer

Dans `Sutura.Application/Interfaces/` :

```csharp
public interface IFileStorageService
{
    Task<StoredFileResult> UploadAsync(
        Stream content,
        string fileName,
        string contentType,
        string folderId,
        CancellationToken cancellationToken);

    Task<Stream> DownloadAsync(
        string fileId,
        CancellationToken cancellationToken);

    Task DeleteAsync(
        string fileId,
        CancellationToken cancellationToken);
}
```

Dans `Sutura.Infrastructure/GoogleDrive/` :
- `GoogleDriveService` : appels Google Drive API.
- `GoogleOAuthService` : échange/renouvellement des jetons.
- `GoogleDriveOptions` : configuration.
- `DriveFolderManager` : création/récupération des dossiers.
- `GoogleTokenProtector` : chiffrement/déchiffrement du refresh token.

Les interfaces restent dans Application ; l'implémentation Google reste dans Infrastructure.

## 5. Upload d'une photo

1. Flutter envoie une image à `POST /api/v1/models/{id}/photos`.
2. L'API authentifie l'utilisateur et vérifie qu'il possède le modèle.
3. L'API valide taille, extension, signature/type réel et MIME autorisé.
4. L'API transmet le flux à `IFileStorageService`.
5. Google Drive crée le fichier dans `ModelPhotos/<model-id>`.
6. L'API enregistre `drive_file_id` et métadonnées dans `DriveFiles` et `ModelPhotos`.
7. L'API renvoie une réponse sans URL publique permanente.

Si l'envoi Drive réussit mais l'enregistrement PostgreSQL échoue, effectuer une suppression compensatoire du fichier Drive ou enregistrer l'opération comme orpheline à réconcilier. Prévoir des timeouts et une gestion des erreurs réseau.

## 6. Affichage et téléchargement

Ne pas utiliser `webViewLink` comme URL d'image publique. Pour afficher une photo :
- l'API vérifie à nouveau le propriétaire ;
- elle récupère le fichier via son identifiant Drive ;
- elle renvoie le flux avec le bon `Content-Type`, ou une URL temporaire sécurisée si cette stratégie est retenue.

Le téléchargement via proxy API est plus simple à sécuriser, mais consomme la bande passante du serveur. Une URL temporaire doit avoir une durée courte et ne pas être enregistrée comme référence durable.

## 7. Sauvegardes PostgreSQL

### Procédure

1. Déclencher une sauvegarde à un moment cohérent (ou bloquer brièvement les opérations sensibles si nécessaire).
2. Exporter PostgreSQL avec `pg_dump` dans un format restaurable (`custom` recommandé).
3. Calculer un checksum SHA-256.
4. Créer un manifeste contenant : identifiant, date UTC, version de l'application, version du schéma, taille, checksum et format.
5. Envoyer le dump et le manifeste dans `Backups`.
6. Vérifier que l'upload est terminé et que le fichier Drive existe.
7. Enregistrer le résultat dans `BackupRecords`.
8. Conserver également une copie serveur selon la politique de rétention configurée.

Ne jamais considérer une sauvegarde réussie uniquement parce que `pg_dump` a terminé : l'envoi distant et la vérification doivent aussi réussir.

### Restauration

- Restaurer d'abord dans une base temporaire/test.
- Vérifier le checksum et la compatibilité de version.
- Effectuer une sauvegarde de l'état actuel avant toute restauration réelle.
- Confirmer explicitement l'opération.
- Utiliser `pg_restore` avec des privilèges adaptés.
- Vérifier ensuite les données et le fonctionnement de l'API.

La restauration ne doit pas être ouverte comme une action ordinaire et silencieuse depuis l'application mobile.

## 8. Sécurité

- Fichiers Drive privés ; aucun partage public automatique.
- Jetons OAuth chiffrés au repos.
- Clé de chiffrement stockée hors de PostgreSQL et du dépôt Git.
- HTTPS obligatoire hors développement local.
- Contrôle de propriété à chaque opération.
- Taille maximale configurable (valeur initiale à décider, par exemple 10 Mo par photo).
- Liste blanche de types d'image (JPEG, PNG, WebP selon prise en charge).
- Journaux sans jetons ni données personnelles inutiles.
- Déconnexion : révoquer le jeton si possible, supprimer les credentials locaux et conserver les fichiers Drive selon le choix de l'utilisateur.

## 9. Gestion des pannes et synchronisation

- Si Drive est indisponible, ne pas perdre les données de commande ou de client.
- Une photo dont l'upload échoue doit être signalée comme non synchronisée et pouvoir être réessayée.
- Une sauvegarde échouée reste `Failed`, avec message technique non sensible.
- Prévoir une tâche de vérification des références Drive pour détecter les fichiers supprimés manuellement.
- Le MVP n'implémente pas encore une synchronisation multi-appareils ni une file de synchronisation offline complexe.

## 10. Points à confirmer

- Taille maximale réelle des photos.
- Politique de conservation et nombre de sauvegardes.
- Fréquence de sauvegarde automatique.
- L'utilisateur souhaite-t-il pouvoir choisir un autre compte Google ?
- Les photos doivent-elles être accessibles hors ligne sur le téléphone ? (Dans ce cas, Flutter conservera un cache local, distinct de la base.)
