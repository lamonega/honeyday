import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Keeps a failed rename open so the title can be retried without retyping.
class RenameAgendaDialog extends StatefulWidget {
  const RenameAgendaDialog({
    required this.initialTitle,
    required this.onSave,
    super.key,
  });

  final String initialTitle;
  final Future<void> Function(String title) onSave;

  @override
  State<RenameAgendaDialog> createState() => _RenameAgendaDialogState();
}

class _RenameAgendaDialogState extends State<RenameAgendaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final title = _title.text.trim();
    if (title == widget.initialTitle) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(title);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      debugPrint('Honeyday: rename failed: $error');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(l10n.agendaRename),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.agendaNewHint),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.agendaTitleRequired
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.agendaRenameError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.agendaSave),
          ),
        ],
      ),
    );
  }
}
