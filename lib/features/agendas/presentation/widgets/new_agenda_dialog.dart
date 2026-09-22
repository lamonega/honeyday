import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/core/theme/design_tokens.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/core/utils/color_utils.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda/agenda_cover_picker.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda/agenda_cover_preview.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda/agenda_paper_style_picker.dart';

/// Default cover style for new agendas.
/// Referenced by: new_agenda_dialog.dart (local definition),
/// features/agendas/presentation/pages/home_page.dart (imported from this file)
const String kDefaultCoverStyle = 'honey';

/// Modal dialog for creating a new agenda notebook.
///
/// What: Collects title, cover theme color, and initial paper texture with a live cover preview.
/// Why: Provides a delightful and tactile creation flow before opening the canvas editor.
class NewAgendaDialog extends StatefulWidget {
  /// Constructs a [NewAgendaDialog].
  const NewAgendaDialog({super.key});

  @override
  State<NewAgendaDialog> createState() => _NewAgendaDialogState();
}

class _NewAgendaDialogState extends State<NewAgendaDialog>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  String _selectedCover = '#D97706';
  String _selectedPaper = kDefaultPaperStyle;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  bool _defaultTitleSet = false;

  static const _presetColors = <String>[
    '#D97706',
    '#8B5CF6',
    '#10B981',
    '#F43F5E',
    '#475569',
    '#2563EB',
    '#EA580C',
    '#7C3AED',
  ];

  static Map<String, String> _paperStyles(BuildContext context) =>
      PaperStyle.localizedLabels(context);

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _animController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationNormal,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_defaultTitleSet) {
      _defaultTitleSet = true;
      _titleController.text = l10n.agendaNewDefaultTitle;
    }
    final activeColor = hexToColor(_selectedCover);
    final darkColor = darken(activeColor);
    final previewTitle = _titleController.text.trim().isEmpty
        ? (l10n.agendaNewTitle)
        : _titleController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          l10n.agendaNewTitle,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AgendaCoverPreview(
                    title: previewTitle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [activeColor, darkColor],
                    ),
                    shadowColor: activeColor,
                  ),
                ),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.agendaNewHint,
                    prefixIcon: const Icon(Icons.book_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                AgendaCoverPicker(
                  colors: _presetColors,
                  selectedCover: _selectedCover,
                  onColorSelected: (hex) =>
                      setState(() => _selectedCover = hex),
                ),
                const SizedBox(height: 20),
                AgendaPaperStylePicker(
                  styles: _paperStyles(context),
                  selectedPaper: _selectedPaper,
                  onPaperSelected: (key) =>
                      setState(() => _selectedPaper = key),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              unawaited(HapticFeedback.lightImpact());
              Navigator.of(context).pop({
                'title': title,
                'coverStyle': _selectedCover,
                'paperStyle': _selectedPaper,
              });
            },
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );
  }
}
