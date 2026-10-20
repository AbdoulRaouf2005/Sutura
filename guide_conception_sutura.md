# Sutura — Guide de conception et conventions du projet

**Version :** 1.0  
**Application :** Android, Flutter/Dart  
**Objectif de ce document :** centraliser les choix visuels, les conventions d'interface, la structure du code, les textes et les règles d'utilisation des icônes pour que tous les écrans restent cohérents.

> Les choix ci-dessous sont la base de conception initiale. Ils peuvent être ajustés après validation avec le couturier et tests sur un vrai téléphone.

---

## 1. Identité de l'application

- **Nom :** Sutura
- **Sens du nom :** « habillement / vêtement » en haoussa, selon le choix du projet.
- **Slogan proposé :** « Le savoir-faire, mieux organisé. »
- **Promesse :** aider le couturier à gérer ses clients, modèles, mensurations, commandes, échéances et paiements, même hors connexion.
- **Ton rédactionnel :** humain, clair, direct, professionnel et simple.
- **Langue de l'interface :** français.
- **Public principal :** couturier indépendant utilisant un téléphone Android.

Ne pas ajouter de slogans marketing dans chaque écran. Le nom et le slogan sont surtout destinés à l'écran de démarrage, à la page À propos et aux supports de présentation.

---

## 2. Palette de couleurs

Palette de départ proposée : une identité sombre et élégante, avec un accent violet pour donner à Sutura une apparence reconnaissable, sans sacrifier la lisibilité.

| Rôle | Couleur | Hex |
|---|---|---|
| Couleur principale | Violet profond | `#662079` |
| Couleur principale pressée | Violet foncé | `#51205F` |
| Accent | Violet vif | `#8B5CF6` |
| Fond général | Gris très clair | `#F7F7FA` |
| Surface/carte | Blanc | `#FFFFFF` |
| Texte principal | Anthracite | `#202124` |
| Texte secondaire | Gris | `#666875` |
| Bordures | Gris clair | `#E4E4EA` |
| Succès | Vert | `#218653` |
| Avertissement | Ambre foncé | `#946200` |
| Erreur | Rouge | `#B42318` |
| Fond sombre | Presque noir | `#17141A` |
| Surface sombre | `#242027` | `#242027` |
| Texte sombre principal | Blanc cassé | `#F7F4F8` |

### Utilisation
- Le violet est réservé aux actions principales, éléments sélectionnés et marqueurs de navigation.
- Les fonds doivent rester neutres pour que les photos de vêtements soient mises en valeur.
- Le vert, l'ambre et le rouge sont réservés aux états de statut ; ne pas les utiliser comme couleurs décoratives.
- Toujours vérifier le contraste du texte, notamment sur les boutons colorés.
- Ne pas afficher un statut uniquement par la couleur : toujours inclure un libellé.

---

## 3. Thème Flutter

- Utiliser `Material 3`.
- Centraliser le thème clair et, si nécessaire, le thème sombre dans un fichier dédié.
- Utiliser des composants cohérents pour les boutons, champs, cartes, dialogues et barres de navigation.
- Préférer des tailles de texte lisibles et des zones tactiles confortables.
- Éviter les ombres fortes, les dégradés décoratifs et les animations excessives.
- Prévoir les états chargement, vide, erreur et succès.

### Direction visuelle
- Simple, soignée, pratique et chaleureuse.
- Les photos de vêtements sont le contenu visuel principal de la galerie.
- Cartes sobres, coins arrondis modérés, espaces réguliers.
- Écrans de formulaire courts, avec regroupements logiques.
- Les actions primaires doivent être clairement identifiables.

### Échelle de rayons suggérée
- Petits éléments/champs : 8 px.
- Boutons et cartes : 12 px.
- Grandes surfaces ou feuilles modales : 16 px.
- Pastilles de statut : forme capsule.

### Espacement suggéré
Utiliser une échelle cohérente fondée sur 4 px : 4, 8, 12, 16, 24 et 32 px. Éviter les valeurs arbitraires répétées dans les écrans ; centraliser les constantes si elles sont utilisées à plusieurs endroits.

---

## 4. Typographie

Utiliser la police système par défaut dans la V1, sauf besoin confirmé. Cela évite d'ajouter des fichiers de police et garde l'application légère.

Hiérarchie indicative :
- Titre d'écran : 24 px, semi-gras.
- Titre de section : 18 px, semi-gras.
- Titre de carte : 16 px, semi-gras.
- Texte courant : 14–16 px.
- Libellé de champ : 14 px.
- Texte secondaire : 12–14 px.
- Bouton : 14–16 px, semi-gras.

Éviter les longs textes en majuscules. Les montants doivent être faciles à repérer.

---

## 5. Icônes

### Package d'icônes
Le projet Flutter généré contient généralement `cupertino_icons`. Il peut être conservé pour les icônes Cupertino si nécessaire, mais l'interface principale recommandée utilise les icônes Material intégrées à Flutter via `Icons.*`. Il n'est pas nécessaire d'ajouter un package d'icônes supplémentaire dans la V1.

### Correspondances proposées
| Usage | Icône Material suggérée |
|---|---|
| Accueil | `Icons.home_outlined` |
| Clients | `Icons.people_outline` |
| Commandes | `Icons.assignment_outlined` |
| Galerie de modèles | `Icons.photo_library_outlined` |
| Ajouter | `Icons.add` |
| Recherche | `Icons.search` |
| Mensurations | `Icons.straighten` |
| Paiements | `Icons.payments_outlined` |
| Calendrier/livraison | `Icons.calendar_month_outlined` |
| Réglages | `Icons.settings_outlined` |
| Modifier | `Icons.edit_outlined` |
| Archiver | `Icons.archive_outlined` |
| Supprimer | `Icons.delete_outline` |
| Appareil photo | `Icons.photo_camera_outlined` |
| Importer une image | `Icons.image_outlined` |
| Retour | `Icons.arrow_back` |
| Plus d'options | `Icons.more_vert` |
| Alerte | `Icons.warning_amber_rounded` |
| Succès | `Icons.check_circle_outline` |
| Téléphone | `Icons.phone_outlined` |
| Notes | `Icons.notes_outlined` |

Toujours choisir les icônes à partir de la bibliothèque réellement utilisée et vérifier leur disponibilité avec la version Flutter du projet. Ne pas mélanger plusieurs familles d'icônes sans raison. Une icône accompagnant une action importante doit avoir un libellé accessible ou un tooltip.

---

## 6. Navigation

Barre de navigation inférieure avec quatre destinations :
1. Accueil
2. Clients
3. Commandes
4. Réglages

La galerie est accessible :
- par une carte/raccourci sur l'accueil ;
- depuis le formulaire de création/modification de commande.

Les mensurations sont accessibles depuis la fiche client et la commande. Les paiements sont accessibles depuis les détails d'une commande.

La navigation doit être simple, avec un retour cohérent et sans empiler inutilement des écrans identiques.

---

## 7. Structure de projet définie

Structure cible :

```text
sutura/
├── android/
├── assets/
│   ├── images/
│   └── icons/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   └── database_migrations.dart
│   │   ├── storage/
│   │   │   └── local_image_storage.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_theme.dart
│   │   │   └── app_spacing.dart
│   │   └── utils/
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── clients/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── measurements/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── gallery/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── orders/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── payments/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── settings/
│   │       └── screens/
│   └── shared/
│       ├── widgets/
│       └── formatters/
├── test/
└── pubspec.yaml
```

### Conventions d'architecture
- `models/` : objets Dart représentant les données.
- `data/` : accès SQLite et opérations de données.
- `screens/` : écrans complets.
- `widgets/` : composants réutilisables de la fonctionnalité.
- `core/` : services partagés, thème, base et stockage local.
- `shared/` : widgets et formateurs réutilisés par plusieurs fonctionnalités.

Ne pas créer tous les dossiers vides d'avance si cela gêne l'apprentissage : créer les dossiers au moment de développer chaque fonctionnalité, tout en conservant cette organisation comme cible.

---

## 8. Dépendances de la V1

Dépendances principales proposées :
- `sqflite` : SQLite sur Android.
- `path` : construction des chemins de fichiers.
- `image_picker` : prendre ou sélectionner une photo.
- `go_router` : navigation.

Dépendances possibles plus tard :
- `path_provider` : trouver les répertoires de l'application pour les fichiers locaux ;
- `intl` : formatage des dates et montants ;
- `flutter_local_notifications` : rappels locaux de livraison ;
- `uuid` : identifiants stables ;
- `flutter_riverpod` : gestion de l'état, seulement si la complexité le justifie.

Ne pas ajouter toutes les dépendances à l'avance. Ajouter un package au moment où une fonctionnalité en a besoin, vérifier sa compatibilité avec le Flutter installé et lire sa documentation.

### `cupertino_icons`
`cupertino_icons` est souvent présent dans le `pubspec.yaml` créé par Flutter. Il fournit les icônes de style iOS/Cupertino. Il peut rester dans le projet même si la cible est Android, mais les icônes Material (`Icons.*`) sont le choix principal pour Sutura. Il n'est pas nécessaire de l'utiliser partout ni de le supprimer uniquement pour cette raison.

---

## 9. Textes et microcopie

Employer les libellés suivants de façon cohérente.

### Navigation
- Accueil
- Clients
- Commandes
- Réglages

### Actions
- Ajouter un client
- Enregistrer le client
- Modifier les informations
- Ajouter des mensurations
- Ajouter un modèle
- Prendre une photo
- Choisir une photo
- Enregistrer le modèle
- Nouvelle commande
- Enregistrer la commande
- Ajouter un paiement
- Enregistrer le paiement
- Annuler
- Confirmer
- Archiver

### États vides
- Clients : « Aucun client pour le moment. Ajoutez votre premier client pour commencer. »
- Galerie : « Votre galerie est vide. Ajoutez une photo de modèle pour la retrouver facilement lors d'une commande. »
- Commandes : « Aucune commande pour le moment. Créez une commande pour commencer le suivi. »
- Paiements : « Aucun paiement enregistré pour cette commande. »

### Validation et erreurs
- Champ obligatoire : « Ce champ est obligatoire. »
- Téléphone : « Vérifiez le numéro de téléphone. »
- Montant invalide : « Saisissez un montant supérieur à zéro. »
- Quantité invalide : « La quantité doit être au moins égale à 1. »
- Date manquante : « Choisissez une date de livraison. »
- Photo indisponible : « Cette image n'est plus disponible. Choisissez une autre photo. »
- Erreur de sauvegarde : « L'enregistrement a échoué. Réessayez. »

### Confirmation d'archivage
« Archiver cet élément ? Il ne sera plus proposé dans les nouvelles sélections, mais son historique sera conservé. »

Ne pas annoncer qu'une donnée est sauvegardée tant que l'opération SQLite n'a pas réussi.

---

## 10. Formats et conventions de données

- Dates stockées en ISO 8601 ; affichage local lisible en français.
- Unité de mesure initiale : centimètre (`cm`), à confirmer.
- Devise initiale proposée : FCFA / XOF, à confirmer.
- Montants monétaires stockés comme entiers en FCFA pour éviter les erreurs de précision.
- Valeurs de mensurations stockées en numérique.
- Identifiants stables, idéalement UUID.
- Photos stockées comme fichiers dans le répertoire privé de l'application ; SQLite conserve le chemin local.
- Activer et vérifier les clés étrangères SQLite.
- Utiliser des migrations versionnées lorsque le schéma change.

---

## 11. Accessibilité et comportement d'interface

- Les boutons ont des libellés explicites.
- Les zones tactiles sont suffisamment grandes.
- Les erreurs apparaissent près du champ concerné.
- Les champs conservent leur saisie lorsque c'est possible après une erreur de validation.
- Les statuts comportent une icône ou un texte, pas seulement une couleur.
- Les photos de la galerie disposent d'un texte alternatif/label accessible.
- Les écrans gèrent les petits écrans et le clavier virtuel.
- Les formulaires préviennent avant de perdre une saisie non enregistrée.
- Les listes longues doivent rester fluides et proposer une recherche lorsque nécessaire.

---

## 12. Principes de développement

1. Développer et tester une fonctionnalité à la fois.
2. Garder la V1 entièrement utilisable sans Internet.
3. Ne pas coder un backend ou une synchronisation dans cette phase.
4. Tester les opérations SQLite sur un appareil Android réel.
5. Valider les listes de mensurations et catégories avec le couturier.
6. Prioriser la fiabilité des données et la rapidité d'utilisation plutôt que les animations.
7. Faire une sauvegarde avant les changements importants du schéma.
8. Ne jamais prétendre que l'export/restauration fonctionne avant de l'avoir testé avec les photos.
9. Garder le design cohérent entre tous les écrans.
10. Documenter les décisions métier qui changent le comportement de l'application.
