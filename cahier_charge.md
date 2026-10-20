# Sutura — Cahier des charges fonctionnel et technique (V1)

**Version :** 1.0  
**Plateforme cible :** Android  
**Stack :** Flutter, Dart, SQLite (`sqflite`)  
**Mode :** hors ligne, sans backend pour la V1  
**Nom :** Sutura  
**Slogan proposé :** « Le savoir-faire, mieux organisé. »

---

## 1. Présentation du projet

Sutura est une application mobile destinée à aider un couturier indépendant à organiser le travail de son atelier. Elle remplace progressivement les notes papier par un outil simple pour gérer les clients, leurs mensurations, les modèles de vêtements, les commandes, les échéances et les paiements.

La V1 doit être utilisable sans connexion Internet. Toutes les données métier sont conservées localement sur le téléphone.

### 1.1 Objectifs

- Retrouver rapidement les informations d'un client.
- Conserver les mensurations et leur historique.
- Constituer une galerie personnelle de modèles de vêtements.
- Relier un modèle, un client et les mensurations à une commande.
- Suivre les dates de livraison et l'état des commandes.
- Enregistrer les avances et les paiements partiels.
- Voir le montant payé et le reste à payer.
- Réduire les oublis et faciliter le suivi quotidien de l'atelier.

### 1.2 Périmètre de la V1

Inclus :
- tableau de bord local ;
- gestion des clients ;
- mensurations ;
- galerie de modèles avec ajout de photos ;
- commandes et statuts ;
- paiements ;
- recherche et filtres simples ;
- paramètres essentiels ;
- sauvegarde/export local à définir et tester avant usage réel.

Non inclus dans la V1 :
- compte utilisateur en ligne ;
- API ou backend ;
- synchronisation entre appareils ;
- stockage distant des photos ;
- partage de données entre plusieurs couturiers ;
- statistiques avancées ;
- facturation ou comptabilité complète ;
- paiement mobile intégré.

---

## 2. Utilisateur et contexte d'utilisation

La V1 vise d'abord un seul couturier utilisant l'application sur un téléphone Android. L'application doit être simple, lisible, utilisable rapidement dans un atelier et tolérante aux interruptions.

Les libellés doivent être en français. Les textes doivent être courts et compréhensibles par une personne qui n'est pas spécialiste de l'informatique.

---

## 3. Navigation principale

Navigation principale recommandée : barre de navigation inférieure avec quatre destinations.

1. **Accueil** — vue synthétique de l'activité.
2. **Clients** — liste, recherche et profils clients.
3. **Commandes** — commandes et suivi des échéances.
4. **Réglages** — préférences et sauvegarde.

La galerie est accessible depuis un raccourci de l'accueil et depuis le formulaire de commande. Les mensurations et les paiements sont accessibles depuis la fiche du client ou la commande concernée.

---

## 4. Fonctionnalités détaillées

### 4.1 Tableau de bord

Afficher des informations utiles sans surcharger l'écran :
- nombre de commandes en cours ;
- commandes à livrer prochainement ;
- commandes en retard ;
- total restant à encaisser, calculé à partir des commandes actives selon les règles métier retenues ;
- raccourcis « Nouveau client », « Nouvelle commande » et « Galerie ».

Chaque indicateur doit ouvrir la liste correspondante lorsqu'il est interactif.

État vide : expliquer brièvement quoi faire en premier et proposer un bouton d'action.

### 4.2 Clients

Fonctions :
- créer un client ;
- modifier ses informations ;
- rechercher par nom ou numéro de téléphone ;
- consulter la fiche et l'historique des commandes ;
- consulter ses mensurations ;
- archiver un client si nécessaire.

Champs proposés :
- identifiant unique ;
- nom complet (obligatoire) ;
- numéro de téléphone (facultatif, mais recommandé) ;
- note générale (facultative) ;
- date de création et date de mise à jour ;
- indicateur d'archivage.

Règles :
- ne pas créer de doublon automatiquement sur la seule base du nom ;
- demander confirmation avant une action destructive ;
- un client ayant des commandes ne doit pas être supprimé physiquement sans traitement de ses données liées ; préférer l'archivage.

### 4.3 Mensurations

Fonctions :
- enregistrer un jeu de mensurations pour un client ;
- identifier le type de vêtement ou l'usage des mesures ;
- consulter les mensurations précédentes ;
- créer une nouvelle version sans écraser l'historique ;
- ajouter une note facultative.

La liste exacte des mesures doit être validée avec le couturier avant d'être figée dans l'interface. Prévoir une configuration initiale modifiable dans le code, par exemple : tour de poitrine, tour de taille, tour de hanches, longueur, épaules, manche, entrejambe, cou et autres mesures à confirmer. Ne pas présenter cette liste comme définitive sans validation métier.

Chaque mesure comprend un nom, une valeur numérique et une unité cohérente (par défaut centimètres). Valider que la valeur est numérique et positive. Conserver la date de prise des mesures.

Règle importante : une commande doit référencer le jeu de mensurations utilisé au moment de sa création, afin qu'une nouvelle prise de mesures ne modifie pas rétroactivement une ancienne commande.

### 4.4 Galerie de modèles de vêtements

La galerie est une fonctionnalité centrale de Sutura. Le couturier doit pouvoir créer et entretenir sa propre collection de modèles ; la galerie ne doit pas être limitée à des modèles préinstallés.

Fonctions :
- afficher les modèles en grille avec leur photo principale ;
- ajouter un nouveau modèle ;
- prendre une photo avec l'appareil photo ou choisir une image existante ;
- saisir ou modifier le nom du modèle ;
- sélectionner une catégorie ;
- ajouter une description ou des notes facultatives ;
- rechercher par nom ;
- filtrer par catégorie ;
- remplacer la photo ;
- modifier les informations ;
- archiver un modèle qui n'est plus proposé.

Champs proposés :
- identifiant unique ;
- nom du modèle (obligatoire) ;
- catégorie (facultative au départ) ;
- description/notes (facultatives) ;
- chemin de la photo principale locale ;
- date de création et date de mise à jour ;
- indicateur d'archivage.

Catégories de départ possibles, à ajuster avec le couturier : Boubou, Kaftan, Robe, Chemise, Pantalon, Tenue traditionnelle, Autre.

Règles :
- une photo principale maximum par modèle dans la V1 ;
- la photo peut être facultative, mais l'interface doit encourager l'ajout d'une photo ;
- copier l'image choisie dans le stockage privé de l'application plutôt que de conserver uniquement un chemin temporaire fourni par le sélecteur ;
- redimensionner/comprimer les images de façon raisonnable pour éviter de remplir rapidement le téléphone ;
- conserver le modèle associé à une commande historique même si le modèle est ensuite modifié ou archivé ;
- préférer l'archivage à la suppression définitive d'un modèle déjà utilisé par une commande.

### 4.5 Commandes

Fonctions :
- créer une commande depuis une fiche client ou depuis l'écran Commandes ;
- sélectionner un client existant ;
- sélectionner un modèle de la galerie ou choisir « Modèle personnalisé / aucun modèle » ;
- associer le jeu de mensurations pertinent ;
- saisir la description, la quantité, le prix et la date de livraison ;
- modifier l'état d'avancement ;
- consulter l'historique et les détails de la commande.

Champs proposés :
- identifiant unique ;
- identifiant du client ;
- identifiant du modèle, facultatif ;
- nom du modèle au moment de la commande (copie historique) ;
- chemin/photo de référence au moment de la commande si nécessaire ;
- identifiant du jeu de mensurations utilisé, facultatif ;
- description ;
- quantité (entier supérieur ou égal à 1) ;
- prix total convenu ;
- date de création ;
- date/heure de livraison prévue ;
- statut ;
- notes facultatives ;
- dates de création et de mise à jour.

Statuts proposés :
- À commencer ;
- En cours ;
- Prête ;
- Livrée ;
- Annulée.

« En retard » est un état calculé, pas un statut enregistré : une commande est en retard si sa date de livraison est passée et qu'elle n'est ni livrée ni annulée.

Règles :
- le prix total doit être supérieur ou égal à zéro ;
- la date de livraison est requise pour une commande planifiée ;
- l'identifiant de commande reste stable ;
- une commande conserve son nom de modèle et son jeu de mensurations de référence même si le modèle ou les mesures du client changent par la suite ;
- avant d'annuler une commande ayant des paiements, demander une confirmation et conserver l'historique financier.

### 4.6 Paiements

Fonctions :
- enregistrer une avance ou un versement ;
- consulter les versements d'une commande ;
- calculer le total payé et le solde restant.

Champs proposés :
- identifiant unique ;
- identifiant de la commande ;
- montant ;
- date du versement ;
- méthode (facultative : espèces, transfert, autre) ;
- note facultative.

Règles :
- montant strictement supérieur à zéro ;
- total payé = somme des paiements associés à la commande ;
- solde restant = prix total de la commande − total payé ;
- afficher clairement un éventuel trop-perçu si les paiements dépassent le prix total, plutôt que de masquer la différence ;
- ne pas écraser un ancien paiement lors d'une correction : prévoir une modification contrôlée ou une annulation traçable selon le niveau de complexité retenu ;
- ne pas supposer un moyen de paiement mobile intégré dans la V1.

### 4.7 Réglages et sauvegarde

V1 :
- afficher le nom de l'application et sa version ;
- choisir l'unité de mesure par défaut si cette option est nécessaire ;
- choisir la devise d'affichage, avec FCFA/XOF comme valeur initiale proposée à confirmer ;
- proposer une procédure de sauvegarde/export et de restauration locale, à tester sur un vrai appareil ;
- afficher un avertissement indiquant que les données restent sur l'appareil.

La sauvegarde ne doit pas être déclarée opérationnelle tant que l'export et la restauration n'ont pas été réellement implémentés et testés. Une simple copie de la base peut ne pas suffire si les photos sont stockées séparément : la sauvegarde doit inclure les fichiers image et leurs références.

---

## 5. Modèle de données SQLite initial

Les noms ci-dessous sont indicatifs et peuvent être adaptés au code. Utiliser des identifiants stables, de préférence des UUID générés côté application, afin de faciliter une éventuelle synchronisation future.

### `clients`
- `id` TEXT PRIMARY KEY
- `full_name` TEXT NOT NULL
- `phone` TEXT NULL
- `notes` TEXT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `is_archived` INTEGER NOT NULL DEFAULT 0

### `measurement_sets`
- `id` TEXT PRIMARY KEY
- `client_id` TEXT NOT NULL
- `garment_type` TEXT NOT NULL
- `notes` TEXT NULL
- `measured_at` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`)

### `measurements`
- `id` TEXT PRIMARY KEY
- `measurement_set_id` TEXT NOT NULL
- `name` TEXT NOT NULL
- `value` REAL NOT NULL
- `unit` TEXT NOT NULL DEFAULT 'cm'
- FOREIGN KEY (`measurement_set_id`) REFERENCES `measurement_sets` (`id`)

### `garment_models`
- `id` TEXT PRIMARY KEY
- `name` TEXT NOT NULL
- `category` TEXT NULL
- `description` TEXT NULL
- `local_image_path` TEXT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `is_archived` INTEGER NOT NULL DEFAULT 0

### `orders`
- `id` TEXT PRIMARY KEY
- `client_id` TEXT NOT NULL
- `garment_model_id` TEXT NULL
- `model_name_snapshot` TEXT NULL
- `model_image_snapshot_path` TEXT NULL
- `measurement_set_id` TEXT NULL
- `description` TEXT NULL
- `quantity` INTEGER NOT NULL DEFAULT 1
- `total_price` INTEGER NOT NULL
- `delivery_at` TEXT NOT NULL
- `status` TEXT NOT NULL
- `notes` TEXT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`)
- FOREIGN KEY (`garment_model_id`) REFERENCES `garment_models` (`id`)
- FOREIGN KEY (`measurement_set_id`) REFERENCES `measurement_sets` (`id`)

Le prix en FCFA peut être conservé comme entier afin d'éviter les erreurs de virgule flottante pour les montants monétaires.

### `payments`
- `id` TEXT PRIMARY KEY
- `order_id` TEXT NOT NULL
- `amount` INTEGER NOT NULL
- `paid_at` TEXT NOT NULL
- `method` TEXT NULL
- `note` TEXT NULL
- FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)

### Notes d'implémentation SQLite
- activer les clés étrangères avec `PRAGMA foreign_keys = ON` sur chaque connexion appropriée ;
- utiliser des transactions pour enregistrer un jeu de mensurations et toutes ses mesures ;
- créer des index sur les colonnes fréquemment recherchées, notamment nom/téléphone, `client_id`, `delivery_at`, `status` et `order_id` ;
- gérer les migrations de schéma avec un numéro de version de base ;
- enregistrer les dates en ISO 8601 ;
- supprimer ou archiver les données avec prudence pour ne pas casser l'historique ;
- stocker les photos comme fichiers, pas comme gros blobs SQLite.

---

## 6. Règles métier transversales

1. Les opérations de création et de modification doivent fonctionner hors ligne.
2. Les formulaires doivent afficher des erreurs précises et compréhensibles.
3. Une commande appartient à un client.
4. Un client peut avoir plusieurs commandes et plusieurs jeux de mensurations.
5. Une commande peut référencer un modèle, mais doit aussi pouvoir exister sans modèle de la galerie.
6. Les modifications ultérieures des mensurations ne changent pas les mesures de référence d'une commande passée.
7. Les modèles utilisés dans l'historique ne doivent pas disparaître des commandes lorsque le modèle est archivé.
8. Le solde est calculé, et non saisi manuellement.
9. Les listes doivent proposer un état vide, un indicateur de chargement si nécessaire et une gestion d'erreur.
10. Les actions destructives doivent demander confirmation.

---

## 7. Contraintes de qualité

- Interface adaptée à un téléphone Android.
- Textes en français.
- Écrans simples, lisibles et cohérents.
- Pas de dépendance réseau pour les fonctions métier de la V1.
- Données persistantes après fermeture et redémarrage de l'application.
- Photos stockées dans le répertoire privé de l'application.
- Tests des calculs financiers et des règles de retard.
- Sauvegarde/restauration testée avant utilisation réelle.
- Respect de la confidentialité des données des clients.

---

## 8. Critères d'acceptation de la V1

La V1 est prête à être testée par le couturier lorsque :

- il peut créer, modifier, rechercher et consulter un client ;
- il peut enregistrer plusieurs jeux de mensurations sans écraser les précédents ;
- il peut ajouter un modèle à la galerie avec une photo prise ou importée ;
- il peut modifier ou archiver un modèle ;
- il peut créer une commande associée à un client, à un modèle facultatif et à un jeu de mensurations ;
- il peut changer le statut et retrouver les commandes en retard ;
- il peut enregistrer plusieurs paiements pour une commande ;
- le montant payé et le solde sont calculés correctement ;
- les informations sont toujours présentes après fermeture et réouverture de l'application ;
- les fonctions principales marchent sans Internet ;
- une sauvegarde exportée peut être restaurée et inclut les photos.

---


**Principe de réalisation :** développer d'abord un petit flux complet — client, mensurations, modèle, commande, paiement — puis améliorer les écrans à partir des retours réels du couturier.
