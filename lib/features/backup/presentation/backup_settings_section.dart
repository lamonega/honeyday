import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/backup/presentation/backup_controller.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

enum _BackupStage { idle, working, confirming }

/// Settings entry point. File dialogs and storage live behind the controller.
class BackupSettingsSection extends ConsumerStatefulWidget {
  const BackupSettingsSection({super.key});

  @override
  ConsumerState<BackupSettingsSection> createState() =>
      _BackupSettingsSectionState();
}

class _BackupSettingsSectionState extends ConsumerState<BackupSettingsSection> {
  _BackupStage _stage = _BackupStage.idle;

  bool get _busy => _stage != _BackupStage.idle;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _stage = _BackupStage.working);
    try {
      await operation();
    } on FormatException {
      if (mounted) _message(AppLocalizations.of(context).backupInvalid);
    } on Object catch (error, stack) {
      debugPrint('Honeyday: backup failed: $error\n$stack');
      if (mounted) _message(AppLocalizations.of(context).backupError);
    } finally {
      if (mounted) setState(() => _stage = _BackupStage.idle);
    }
  }

  Future<void> _export() => _run(() async {
    final controller = ref.read(backupControllerProvider);
    final prepared = await controller.exportBackup();
    if (mounted && prepared) {
      _message(AppLocalizations.of(context).backupReady);
    }
  });

  Future<void> _restore() => _run(() async {
    final controller = ref.read(backupControllerProvider);
    final backup = await controller.prepareRestore();
    if (backup == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final summary = backup.summary;
    if (summary.agendas == 0) {
      _message(l10n.backupEmpty);
      return;
    }
    setState(() => _stage = _BackupStage.confirming);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.backupConfirmDescription(
              summary.agendas,
              summary.pages,
              summary.elements,
              summary.strokes,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _stage = _BackupStage.working);
    final count = await controller.restore(backup);
    if (mounted) _message(l10n.backupRestored(count));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            l10n.backupTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.backupPrivacy),
        ),
        if (_stage == _BackupStage.working)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Semantics(
                  label: l10n.backupWorking,
                  child: const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(l10n.backupWorking),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.save_alt_rounded),
          title: Text(l10n.backupExport),
          subtitle: Text(l10n.backupExportDescription),
          onTap: _busy ? null : _export,
        ),
        ListTile(
          leading: const Icon(Icons.restore_page_outlined),
          title: Text(l10n.backupRestore),
          subtitle: Text(l10n.backupRestoreSubtitle),
          onTap: _busy ? null : _restore,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
