import 'package:flutter/material.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// Écran des préférences et de la sauvegarde (cahier des charges §4.7).
class SettingsScreen extends StatefulWidget {
  /// Crée l'écran des réglages.
  const SettingsScreen({super.key});

  /// Crée l'état associé à cet écran.
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// État de [SettingsScreen] gérant les préférences et les opérations de sauvegarde.
class _SettingsScreenState extends State<SettingsScreen> {
  /// Version affichée de l'application.
  static const String _appVersion = '1.0.0';

  /// Indique si un export est en cours.
  bool _exporting = false;

  /// Indique si une restauration est en cours.
  bool _restoring = false;

  /// Lance l'export de la sauvegarde et affiche le résultat à l'utilisateur.
  Future<void> _export() async {
    setState(() => _exporting = true);
    final BackupResult result = await BackupService.instance.shareBackup();
    if (!mounted) return;
    setState(() => _exporting = false);
    // Aucun message si l'utilisateur annule l'opération.
    if (result == BackupResult.cancelled) return;
    final bool ok = result == BackupResult.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sauvegarde partagée / enregistrée.'
              : 'L\'export de la sauvegarde a échoué.',
        ),
        backgroundColor: ok ? null : AppSemanticColors.of(context).error,
      ),
    );
  }

  /// Demande confirmation puis restaure une sauvegarde sélectionnée.
  Future<void> _restore() async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Restaurer une sauvegarde ?',
      message:
          'Toutes les données actuelles seront remplacées par celles '
          'de la sauvegarde. Cette action est irréversible.',
      confirmLabel: 'Restaurer',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _restoring = true);
    final BackupResult result = await BackupService.instance
        .restoreFromPicker();
    if (!mounted) return;
    setState(() => _restoring = false);
    // Aucun message si l'utilisateur annule la sélection.
    if (result == BackupResult.cancelled) return;
    final bool ok = result == BackupResult.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sauvegarde restaurée. L\'application peut nécessiter un '
                    'redémarrage pour un affichage optimal.'
              : 'La restauration a échoué. Vérifiez le fichier zip.',
        ),
        backgroundColor: ok ? null : AppSemanticColors.of(context).error,
      ),
    );
  }

  /// Construit l'interface des réglages et de la sauvegarde.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        actions: const <Widget>[_ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          const _SectionHeader('Application'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sutura'),
              subtitle: const Text('Version $_appVersion'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader('Apparence'),
          const _ThemeSelector(),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader('Préférences'),
          Card(
            child: Column(
              children: const <Widget>[
                ListTile(
                  leading: Icon(Icons.straighten),
                  title: Text('Unité de mesure'),
                  subtitle: Text('Centimètre (cm)'),
                  enabled: false,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.payments_outlined),
                  title: Text('Devise d\'affichage'),
                  subtitle: Text('FCFA / XOF'),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader('Données'),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Sauvegarder mes données'),
                  subtitle: const Text(
                    'Exporte la base et toutes les photos dans un fichier zip.',
                  ),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined),
                  onTap: _exporting ? null : _export,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restaurer une sauvegarde'),
                  subtitle: const Text(
                    'Remplace toutes les données actuelles par le fichier zip sélectionné.',
                  ),
                  trailing: _restoring
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open_outlined),
                  onTap: _restoring ? null : _restore,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).warning
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppSemanticColors.of(context).warning,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Vos données restent uniquement sur cet appareil. '
                    'Testez l\'export et la restauration avant une utilisation réelle.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de section dans l'écran des réglages.
class _SectionHeader extends StatelessWidget {
  /// Crée un en-tête de section.
  const _SectionHeader(this.label);

  /// Libellé de la section.
  final String label;

  /// Construit l'en-tête de section.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Sélecteur de thème : clair, sombre ou suivi du système.
class _ThemeSelector extends StatelessWidget {
  /// Crée le sélecteur de thème.
  const _ThemeSelector();

  /// Construit le sélecteur de thème.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Thème de l\'application',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choisissez l\'apparence claire ou sombre, ou suivez le réglage '
              'de votre appareil.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListenableBuilder(
              listenable: ThemeController.instance,
              builder: (BuildContext context, Widget? child) {
                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text(
                          'Clair',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text(
                          'Sombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(
                          'Système',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    selected: <ThemeMode>{ThemeController.instance.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selection) {
                      // Application du mode de thème sélectionné.
                      ThemeController.instance.setThemeMode(selection.first);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton rapide de bascule clair/sombre dans la barre d'application.
class _ThemeToggleButton extends StatelessWidget {
  /// Crée le bouton de bascule du thème.
  const _ThemeToggleButton();

  /// Construit le bouton de bascule du thème.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (BuildContext context, Widget? child) {
        final ThemeMode mode = ThemeController.instance.themeMode;
        // Détermination du thème effectif affiché.
        final bool isDark =
            mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return IconButton(
          tooltip: isDark ? 'Passer en thème clair' : 'Passer en thème sombre',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            // Bascule entre thème clair et sombre.
            ThemeController.instance.toggleDark(
              systemIsDark:
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark,
            );
          },
        );
      },
    );
  }
}
