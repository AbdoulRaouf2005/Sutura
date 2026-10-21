import 'package:flutter/material.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// Préférences et sauvegarde (cahier des charges §4.7).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = '1.0.0';
  bool _exporting = false;
  bool _restoring = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    final bool ok = await BackupService.instance.shareBackup();
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Sauvegarde partagée / enregistrée.'
            : 'L\'export de la sauvegarde a échoué.'),
        backgroundColor: ok ? null : AppColors.error,
      ),
    );
  }

  Future<void> _restore() async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Restaurer une sauvegarde ?',
      message: 'Toutes les données actuelles seront remplacées par celles '
          'de la sauvegarde. Cette action est irréversible.',
      confirmLabel: 'Restaurer',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _restoring = true);
    final bool ok = await BackupService.instance.restoreFromPicker();
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Sauvegarde restaurée. L\'application peut nécessiter un '
                'redémarrage pour un affichage optimal.'
            : 'La restauration a échoué. Vérifiez le fichier zip.'),
        backgroundColor: ok ? null : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
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
                      'Exporte la base et toutes les photos dans un fichier zip.'),
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
                      'Remplace toutes les données actuelles par le fichier zip sélectionné.'),
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
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

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

