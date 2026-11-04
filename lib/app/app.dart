import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

/// Racine de l'application Sutura.
class SuturaApp extends StatelessWidget {
  const SuturaApp({super.key});

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
