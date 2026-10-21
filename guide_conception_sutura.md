# Guide de conception — Sutura

> **Référence de conception de la V1**
>
> Sutura est une application Android de gestion d’atelier de couture. La première version utilise **Flutter, Dart et SQLite**, sans backend. Elle doit fonctionner hors connexion.
>
> **Signature de marque :** « Sutura — Mon atelier, bien géré »
>
> Ce document définit les couleurs, le thème, les icônes, les textes et la structure du projet. En cas de doute, s’y référer avant d’ajouter un nouveau choix visuel ou technique.

---

## 1. Identité visuelle

### Palette officielle

Les cinq couleurs ci-dessous sont les couleurs de référence extraites de l’image de marque fournie. Conserver leurs codes hexadécimaux.

| Nom | Code HEX | Utilisation recommandée |
|---|---|---|
| **Vert profond** | `#0F5132` | Couleur principale : AppBar, navigation sélectionnée, actions principales et éléments de marque |
| **Or africain** | `#F4B400` | Accent : détails importants, éléments sélectionnés, petites touches décoratives et indicateurs |
| **Orange terre** | `#E76F51` | Alertes non critiques, retards, actions secondaires nécessitant de l’attention |
| **Crème** | `#FAF7F0` | Fond principal, fonds doux et surfaces qui donnent une apparence chaleureuse |
| **Gris foncé** | `#2E2E2E` | Texte principal, icônes neutres et éléments à fort contraste |

### Règles d’utilisation

- Le **vert profond** est la couleur de marque principale.
- Le **crème** sert de fond général pour une interface lumineuse et agréable.
- Le **gris foncé** est utilisé pour le texte courant afin de conserver une bonne lisibilité.
- L’**or africain** doit rester un accent : éviter de l’utiliser pour de longs textes.
- L’**orange terre** doit signaler une information qui mérite l’attention, par exemple une commande en retard. Ne pas l’utiliser comme couleur de fond dominante.
- Ne pas introduire de nouvelles couleurs de marque sans mettre à jour ce guide.
- Pour les erreurs, les succès et les avertissements, utiliser les couleurs de la palette quand cela reste lisible. Ajouter un libellé ou une icône : ne jamais communiquer un état uniquement par la couleur.

### Exemple de constantes Flutter

Créer `lib/core/theme/app_colors.dart` :

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color deepGreen = Color(0xFF0F5132);
  static const Color africanGold = Color(0xFFF4B400);
  static const Color earthOrange = Color(0xFFE76F51);
  static const Color cream = Color(0xFFFAF7F0);
  static const Color darkGray = Color(0xFF2E2E2E);

  // Couleurs fonctionnelles dérivées de la palette.
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E0D7);
  static const Color mutedText = Color(0xFF6B6B6B);
}
```

Les couleurs `white`, `border` et `mutedText` sont des couleurs fonctionnelles neutres, pas des couleurs supplémentaires de marque.

---

## 2. Thème Flutter

Créer `lib/core/theme/app_theme.dart`.

Principes :
- Thème clair en priorité pour la V1.
- Fond général crème.
- Texte principal gris foncé.
- Boutons principaux vert profond, avec texte blanc.
- Or africain réservé aux accents et éléments sélectionnés.
- Cartes avec fond blanc ou crème, bord discret et coins arrondis.
- Champs de formulaire faciles à lire et suffisamment grands pour une utilisation en atelier.
- Éviter les ombres fortes, les dégradés excessifs et les décorations qui gênent la lecture.
- Les écrans doivent rester confortables sur de petits téléphones Android.

Exemple de thème de départ :

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.deepGreen,
    brightness: Brightness.light,
    primary: AppColors.deepGreen,
    secondary: AppColors.africanGold,
    surface: AppColors.white,
    error: AppColors.earthOrange,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.darkGray,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.deepGreen,
          width: 1.5,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
```

> Selon la version de Flutter utilisée, certains types de thème peuvent avoir des noms ou paramètres différents. Si une erreur de compilation apparaît, vérifier l’API de la version installée plutôt que de modifier les couleurs définies.

Dans `main.dart`, appliquer le thème avec `theme: buildAppTheme()`.

---

## 3. Logo et icône de l’application

### Direction approuvée

L’icône de Sutura doit reprendre le symbole de marque fourni :
- fond vert profond ;
- grand « S » stylisé formé par des rubans vert, crème et or africain ;
- aiguille et fil intégrés au symbole ;
- bande décorative avec motifs géométriques inspirés du textile ;
- motif de bobine/tissu dans la partie inférieure ;
- **aucun texte dans l’icône d’application**.

L’orange terre et le gris foncé restent disponibles dans l’interface, mais ne sont pas obligatoires dans l’icône.

### Règles

- Utiliser le fichier d’icône final validé comme source unique.
- Ne pas redessiner un logo différent dans chaque écran.
- Prévoir une version carrée haute résolution et vérifier le rendu avec le masque arrondi Android.
- Garder le symbole centré avec une marge suffisante pour éviter qu’il soit coupé par le masque Android.
- Ne pas recréer l’icône avec des icônes Material ou Cupertino : ce sont des ressources distinctes.
- L’intégration finale dans Android se fera avec un outil de génération d’icône d’application, après validation de l’image définitive.

### Nom et signature

- Nom affiché : **Sutura**
- Signature de marque : **Mon atelier, bien géré**
- Ne pas placer la signature sous l’icône Android.

---

## 4. Icônes dans l’interface

Utiliser en priorité les icônes Material fournies par Flutter (`Icons.*`) pour conserver une interface cohérente.

Le package `cupertino_icons` peut être conservé dans `pubspec.yaml` si le projet l’utilise, mais les icônes Cupertino ne doivent pas être mélangées sans raison avec les icônes Material.

Exemples d’icônes possibles :
- Tableau de bord : `Icons.dashboard_outlined`
- Clients : `Icons.people_outline`
- Mesures : `Icons.straighten`
- Galerie de modèles : `Icons.photo_library_outlined`
- Commandes : `Icons.checkroom` ou `Icons.assignment_outlined`
- Paiements : `Icons.payments_outlined`
- Paramètres : `Icons.settings_outlined`
- Ajouter : `Icons.add`
- Rechercher : `Icons.search`
- Date de livraison : `Icons.calendar_month_outlined`
- Téléphone : `Icons.phone_outlined`

Règles :
- Choisir une icône facile à reconnaître et conserver le même symbole pour une même action dans toute l’application.
- Accompagner les icônes importantes d’un texte, en particulier lorsque leur signification n’est pas évidente.
- Ne pas utiliser une icône comme seul moyen de distinguer une commande en retard, terminée ou annulée.
- Éviter d’ajouter une bibliothèque d’icônes externe si les icônes Flutter suffisent.

---

## 5. Structure des dossiers Flutter

Conserver une structure organisée par fonctionnalité, tout en restant adaptée à un projet débutant.

```text
sutura/
├── docs/
│   ├── cahier_charge.md
│   └── guide_conception_sutura.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   └── database_migrations.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart
│   │   └── utils/
│   ├── features/
│   │   ├── dashboard/
│   │   ├── clients/
│   │   ├── measurements/
│   │   ├── gallery/
│   │   ├── orders/
│   │   ├── payments/
│   │   └── settings/
│   └── shared/
│       └── widgets/
├── assets/
│   ├── images/
│   └── icons/
├── test/
├── pubspec.yaml
└── README.md
```

Chaque fonctionnalité pourra ensuite contenir ses propres écrans, modèles et services. Ne crée pas tous les fichiers vides dès le départ : ajoute-les quand la fonctionnalité commence.

### Navigation principale

La navigation principale comporte quatre destinations :
1. **Accueil** — tableau de bord.
2. **Clients** — liste et fiches clients.
3. **Commandes** — commandes et échéances.
4. **Paramètres** — préférences et sauvegarde.

La galerie, les mensurations et les paiements restent accessibles depuis les écrans concernés et/ou leurs actions dédiées. La galerie doit rester facile à trouver, car le couturier doit pouvoir ajouter ses propres modèles.

---

## 6. Dépendances de la V1

Ajouter uniquement les packages nécessaires au moment où ils sont utilisés.

| Package | Rôle |
|---|---|
| `sqflite` | Lire et écrire dans SQLite sur Android |
| `path` | Construire les chemins de fichiers |
| `image_picker` | Prendre une photo ou choisir une image |
| `go_router` | Gérer la navigation |
| `cupertino_icons` | Icônes Cupertino si elles sont utilisées |
| `flutter_local_notifications` | Rappels locaux de livraison, à ajouter au moment de cette fonctionnalité |

Ne pas ajouter `Dio`, une bibliothèque de synchronisation, un client API ou une dépendance backend dans la V1 : aucun backend n’est prévu à ce stade.

### Commandes d’installation initiales

```bash
flutter pub add sqflite path
flutter pub add image_picker
flutter pub add go_router
```

`cupertino_icons` est souvent déjà présent dans le `pubspec.yaml` généré par Flutter. Vérifier avant de l’ajouter une deuxième fois.

---

## 7. Textes de l’interface

Tous les textes visibles par l’utilisateur doivent être en français dans la V1.

### Navigation

- `Accueil`
- `Clients`
- `Commandes`
- `Paramètres`

### Actions

- `Ajouter un client`
- `Ajouter un modèle`
- `Nouvelle commande`
- `Ajouter un paiement`
- `Modifier`
- `Enregistrer`
- `Annuler`
- `Supprimer`
- `Rechercher`
- `Choisir une photo`
- `Prendre une photo`

### États vides

- Clients : **« Aucun client pour le moment. Ajoutez votre premier client. »**
- Galerie : **« Aucun modèle dans la galerie. Ajoutez une photo de modèle pour la retrouver lors de vos prochaines commandes. »**
- Commandes : **« Aucune commande pour le moment. »**
- Paiements : **« Aucun paiement enregistré pour cette commande. »**

### Messages de confirmation

- Enregistrement : `Les modifications ont été enregistrées.`
- Suppression : `Voulez-vous vraiment supprimer cet élément ? Cette action est irréversible.`
- Photo manquante : `Ajoutez une photo ou choisissez une image.`
- Champ obligatoire : `Ce champ est obligatoire.`
- Téléphone invalide : `Vérifiez le numéro de téléphone.`
- Date invalide : `La date de livraison doit être valide.`

Les textes de confirmation doivent expliquer clairement l’action. Ne pas afficher un message de réussite avant que l’enregistrement local ait réellement réussi.

### Statuts de commande

- `À commencer`
- `En cours`
- `Terminée`
- `Livrée`
- `Annulée`

Le statut **En retard** est calculé à partir de la date de livraison et du statut : il ne doit pas remplacer le statut métier enregistré. Une commande est en retard si sa date est dépassée et qu’elle n’est ni livrée ni annulée.

---

## 8. Principes UX et accessibilité

- Concevoir d’abord pour un téléphone Android.
- Utiliser des zones tactiles confortables, idéalement d’au moins 48 dp de hauteur pour les actions principales.
- Afficher les informations essentielles sans obliger l’utilisateur à ouvrir plusieurs écrans.
- Garder les formulaires courts, avec des libellés explicites.
- Valider les champs et afficher les erreurs près du champ concerné.
- Confirmer les suppressions et les actions difficiles à annuler.
- Afficher les dates dans un format clair, par exemple `20/10/2026`.
- Afficher les montants avec l’unité monétaire configurée ; le FCFA peut être la valeur initiale si cela correspond au fonctionnement de l’atelier.
- Ne pas dépendre d’Internet pour créer ou consulter un client, une mensuration, un modèle, une commande ou un paiement.
- Tester les écrans avec des données réelles et sur le téléphone du couturier.

---

## 9. Photos de la galerie

Dans la V1 :
- Le couturier peut prendre une photo ou importer une image.
- Un modèle possède une photo principale, un nom et éventuellement une catégorie et des notes.
- Copier la photo sélectionnée dans le stockage privé de l’application : ne pas conserver uniquement un chemin temporaire fourni par le sélecteur.
- Enregistrer le chemin local de la photo dans SQLite, pas les octets de l’image dans une colonne classique.
- Prévoir une image de remplacement si le fichier n’est plus disponible.
- Compresser/redimensionner les images de manière raisonnable afin de limiter l’espace utilisé.
- Lorsqu’un modèle est associé à une commande, conserver assez d’informations pour que l’historique de la commande reste compréhensible si le modèle est ensuite modifié ou archivé.

La sauvegarde des photos doit être prise en compte dans le mécanisme de sauvegarde locale de l’application.

---

## 10. Principes de stockage SQLite

- Toutes les données de la V1 sont stockées localement sur l’appareil.
- Les tables et relations doivent être définies dans un emplacement centralisé.
- Utiliser des identifiants stables pour les clients, modèles, commandes et paiements.
- Utiliser des clés étrangères lorsque cela est adapté et activer leur prise en charge dans SQLite.
- Utiliser des transactions pour les opérations qui doivent réussir ensemble, par exemple l’enregistrement d’une commande et de ses informations associées.
- Ne pas supprimer l’historique des mensurations à chaque nouvelle prise de mesure.
- Enregistrer chaque versement comme une opération distincte ; calculer le total payé à partir des versements enregistrés.
- Prévoir une stratégie de versionnement et de migration du schéma de base de données.
- Tester les calculs de solde et les dates de livraison.

**Limite importante :** sans backend, les données ne sont pas automatiquement sauvegardées en ligne. Une désinstallation ou une perte du téléphone peut entraîner leur perte. Prévoir une exportation/restauration locale et expliquer au couturier comment faire une sauvegarde.

---

## 11. Conventions de code

- Noms de classes en `PascalCase` : `Client`, `Order`, `AppDatabase`.
- Variables et méthodes en `camelCase` : `clientName`, `saveOrder()`.
- Fichiers Dart en `snake_case` : `client_form_screen.dart`.
- Éviter les gros widgets qui mélangent interface, SQL et règles métier.
- Mettre les couleurs dans `AppColors`, pas sous forme de valeurs hexadécimales dispersées dans les écrans.
- Réutiliser les widgets communs lorsque cela simplifie réellement le code.
- Écrire des tests pour les calculs sensibles, notamment les paiements et les retards.
- Ne pas implémenter de backend, d’authentification distante ou de synchronisation dans cette V1.

---

## 12. Ordre conseillé de développement

1. Créer le projet Flutter et vérifier son lancement sur Android.
2. Configurer les couleurs, le thème et la navigation.
3. Concevoir la base SQLite et ses migrations.
4. Développer la gestion des clients.
5. Développer les mensurations et leur historique.
6. Développer la galerie de modèles et le stockage des photos.
7. Développer les commandes.
8. Développer les paiements et le calcul des soldes.
9. Développer le tableau de bord et les rappels locaux.
10. Tester le fonctionnement hors connexion, les erreurs et la sauvegarde/restauration.

---

## 13. Règle de référence

En cas de contradiction :
1. Les cinq codes de couleurs officiels de ce document priment sur toute couleur ajoutée précédemment.
2. Le cahier des charges définit les fonctionnalités attendues.
3. Ce guide définit leur présentation visuelle et les conventions de projet.
4. Toute décision non validée avec le couturier doit être considérée comme provisoire et vérifiée avant d'ajouter de la complexité.
