import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/loading_screen.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuturaBootstrap());
}

/// Lance l'application après avoir affiché l'écran de chargement le temps de
/// l'initialisation (localisation des dates et préférences de thème).
class SuturaBootstrap extends StatefulWidget {
  const SuturaBootstrap({super.key});

  @override
  State<SuturaBootstrap> createState() => _SuturaBootstrapState();
}

class _SuturaBootstrapState extends State<SuturaBootstrap> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await initializeDateFormatting('fr_FR');
    await ThemeController.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
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
