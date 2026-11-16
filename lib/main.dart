import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/loading_screen.dart';
import 'core/theme/theme_controller.dart';

/// Point d'entrée de l'application.
///
/// Initialise les liaisons Flutter nécessaires avant le lancement de
/// l'interface utilisateur.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuturaBootstrap());
}

/// Lance l'application après avoir affiché l'écran de chargement le temps de
/// l'initialisation (localisation des dates et préférences de thème).
class SuturaBootstrap extends StatefulWidget {
  /// Crée le widget de démarrage de l'application.
  const SuturaBootstrap({super.key});

  /// Crée l'état associé à ce widget.
  @override
  State<SuturaBootstrap> createState() => _SuturaBootstrapState();
}

/// État associé à [SuturaBootstrap] gérant l'initialisation au démarrage.
class _SuturaBootstrapState extends State<SuturaBootstrap> {
  /// Future représentant l'initialisation asynchrone au démarrage.
  late final Future<void> _initialization;

  /// Démarre l'initialisation de l'application au montage du widget.
  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  /// Initialise les données requises au démarrage (format de dates, thème).
  Future<void> _initialize() async {
    // Chargement des données de localisation française pour les dates.
    await initializeDateFormatting('fr_FR');
    // Chargement du mode de thème sauvegardé par l'utilisateur.
    await ThemeController.instance.load();
  }

  /// Construit l'interface en affichant l'écran de chargement puis l'application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Affiche l'écran de chargement tant que l'initialisation n'est pas terminée.
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoadingScreen(),
          );
        }
        return const SuturaApp();
      },
    );
  }
}
