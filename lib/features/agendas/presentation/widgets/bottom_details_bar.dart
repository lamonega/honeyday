import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom bar showing page count and action buttons for reading/editing.
class BottomDetailsBar extends StatelessWidget {
  const BottomDetailsBar({
    required this.pageCount,
    required this.onOpenReading,
    required this.onOpenEdit,
    super.key,
  });

  final int pageCount;
  final VoidCallback onOpenReading;
  final VoidCallback onOpenEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        children: [
          _PageCountBadge(pageCount: pageCount),
          const Spacer(),
          _ActionButton(
            icon: Icons.visibility_outlined,
            tooltip: 'Modo lectura',
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            onTap: onOpenReading,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.edit_outlined,
            tooltip: 'Modo edición',
            color: colorScheme.primary,
            onTap: onOpenEdit,
          ),
        ],
      ),
    );
  }
}

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.pageCount});

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pageCount ${pageCount == 1 ? 'pág' : 'págs'}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
    );
  }
}
