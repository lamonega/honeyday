import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Confirms and awaits a mutation, keeping failures open for an explicit retry.
class AgendaActionDialog extends StatefulWidget {
  const AgendaActionDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final Future<void> Function() onConfirm;
  final bool destructive;

  @override
  State<AgendaActionDialog> createState() => _AgendaActionDialogState();
}

class _AgendaActionDialogState extends State<AgendaActionDialog> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      debugPrint('Honeyday: agenda operation failed: $error');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
        scrollable: true,
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.agendaActionError,
                  style: TextStyle(color: colors.error),
                ),
              ),
            if (_saving)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  semanticsLabel: l10n.agendaSaving,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: widget.destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            onPressed: _saving ? null : _confirm,
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}
