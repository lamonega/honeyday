import 'package:flutter/material.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Options dialog shown before an export: paper size + content policy.
///
/// What: Lets the user pick A4/Letter and whether typed content and ink are
/// kept (both checked by default), showing the resulting page count.
/// Why: The only place the export flow blocks on the user, which doubles as
/// the window that lets debounced element edits flush to the database.
class ExportOptionsDialog extends StatefulWidget {
  /// Creates the dialog widget (use [show] to open it as a route).
  const ExportOptionsDialog({required this.pageCount, super.key});

  /// Opens the dialog and returns the chosen options, or `null` on cancel.
  static Future<ExportOptions?> show(
    BuildContext context, {
    required int pageCount,
  }) {
    return showDialog<ExportOptions>(
      context: context,
      builder: (_) => ExportOptionsDialog(pageCount: pageCount),
    );
  }

  /// Total pages the export will produce (canvas pages + cover).
  final int pageCount;

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  PdfExportFormat _format = PdfExportFormat.a4;
  bool _includeTypedContent = true;
  bool _includeInk = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.exportDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportFormatLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<PdfExportFormat>(
              segments: [
                const ButtonSegment(
                  value: PdfExportFormat.a4,
                  label: Text('A4'),
                ),
                ButtonSegment(
                  value: PdfExportFormat.letter,
                  label: Text(l10n.exportFormatLetter),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) {
                setState(() => _format = selection.first);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _includeTypedContent,
              onChanged: (value) {
                setState(() => _includeTypedContent = value ?? true);
              },
              title: Text(l10n.exportIncludeContentLabel),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _includeInk,
              onChanged: (value) {
                setState(() => _includeInk = value ?? true);
              },
              title: Text(l10n.exportIncludeInkLabel),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Text(
              l10n.exportTemplateHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exportPagesSummary(widget.pageCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ExportOptions(
              format: _format,
              includeTypedContent: _includeTypedContent,
              includeInk: _includeInk,
            ),
          ),
          child: Text(l10n.exportStart),
        ),
      ],
    );
  }
}
