import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

/// Racine de l'application Sutura.
class SuturaApp extends StatelessWidget {
  /// Crée le widget racine de l'application.
  const SuturaApp({super.key});

  /// Construit l'application en appliquant le thème et la configuration du routeur.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          title: 'Sutura',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
