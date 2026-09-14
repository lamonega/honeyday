import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';

/// Shows a dialog prompting the user to choose the layout/paper design for a new page.
Future<String?> showNewPageDesignDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const NewPageDesignDialog(),
  );
}

/// Modal dialog allowing users to pick a paper design when adding a new agenda page.
class NewPageDesignDialog extends StatefulWidget {
  const NewPageDesignDialog({
    super.key,
    this.initialStyle = PaperStyle.dotted,
  });

  final PaperStyle initialStyle;

  @override
  State<NewPageDesignDialog> createState() => _NewPageDesignDialogState();
}

class _NewPageDesignDialogState extends State<NewPageDesignDialog> {
  late PaperStyle _selectedStyle;

  static const _designs = [
    _PageDesignOption(
      style: PaperStyle.lined,
      title: 'Líneas',
      icon: Icons.view_headline_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.dotted,
      title: 'Puntos',
      icon: Icons.grain_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.blank,
      title: 'En blanco',
      icon: Icons.crop_portrait_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.grid,
      title: 'Cuadrícula',
      icon: Icons.grid_4x4_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.note_add_rounded, color: colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'Diseño de la Página',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildOptionCard(_designs[0], colorScheme)),
                const SizedBox(width: 12),
                Expanded(child: _buildOptionCard(_designs[1], colorScheme)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildOptionCard(_designs[2], colorScheme)),
                const SizedBox(width: 12),
                Expanded(child: _buildOptionCard(_designs[3], colorScheme)),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Crear Página',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pop(_selectedStyle.name),
        ),
      ],
    );
  }

  Widget _buildOptionCard(_PageDesignOption option, ColorScheme colorScheme) {
    final isSelected = _selectedStyle == option.style;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedStyle = option.style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 95,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option.icon,
                    size: 16,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
                Container(
                  width: 44,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: PageSurface(
                      paperStyle: option.style,
                      spacing: 6,
                      margin: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDesignOption {
  const _PageDesignOption({
    required this.style,
    required this.title,
    required this.icon,
  });

  final PaperStyle style;
  final String title;
  final IconData icon;
}
