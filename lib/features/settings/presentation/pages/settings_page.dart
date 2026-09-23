import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/providers/app_version_provider.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/core/theme/design_tokens.dart';
import 'package:honeyday/core/theme/theme_providers.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _accentPresets = <Color>[
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF64748B),
    Color(0xFF14B8A6),
  ];

  static String? _getAccentName(BuildContext context, Color accentColor) {
    final l10n = AppLocalizations.of(context);
    final names = <int, String>{
      const Color(0xFFF59E0B).toARGB32(): l10n.settingsAccentBeeHoney,
      const Color(0xFF8B5CF6).toARGB32(): l10n.settingsAccentLavender,
      const Color(0xFF10B981).toARGB32(): l10n.settingsAccentSage,
      const Color(0xFFEC4899).toARGB32(): l10n.settingsAccentRose,
      const Color(0xFF3B82F6).toARGB32(): l10n.settingsAccentOcean,
      const Color(0xFFEF4444).toARGB32(): l10n.settingsAccentBrick,
      const Color(0xFF64748B).toARGB32(): l10n.settingsAccentGray,
      const Color(0xFF14B8A6).toARGB32(): l10n.settingsAccentTeal,
    };
    return names[accentColor.toARGB32()];
  }

  static const Map<ThemeMode, IconData> _themeModeIcons = {
    ThemeMode.system: Icons.brightness_auto_outlined,
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
  };

  static String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeModeValue = ref.watch(themeModeProvider);
    final themeMode = themeModeValue.hasValue
        ? themeModeValue.value!
        : ThemeMode.system;
    final accentColorValue = ref.watch(accentColorProvider);
    final accentColor = accentColorValue.hasValue
        ? accentColorValue.value!
        : AppColors.honeyAmber;

    final accentName = _getAccentName(context, accentColor);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(
            label: AppLocalizations.of(context).settingsGeneral,
            colorScheme: colorScheme,
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(AppLocalizations.of(context).settingsDarkMode),
            subtitle: Text(
              _themeModeLabel(AppLocalizations.of(context), themeMode),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.arrow_drop_down_rounded),
            onTap: () =>
                unawaited(_showThemeModePicker(context, ref, themeMode)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(AppLocalizations.of(context).settingsAccentColor),
            subtitle: Text(
              accentName ?? AppLocalizations.of(context).settingsAccentCustom,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            onTap: () =>
                unawaited(_showAccentColorPicker(context, ref, accentColor)),
          ),
          const Divider(height: 1),
          _SectionHeader(
            label: AppLocalizations.of(context).settingsAbout,
            colorScheme: colorScheme,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).settingsVersion),
            subtitle: Text(
              ref.watch(appVersionProvider).value ?? '...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(AppLocalizations.of(context).settingsLicenses),
            subtitle: Text(
              AppLocalizations.of(context).settingsLicensesSubtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppLocalizations.of(context).appTitle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDarkMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(_themeModeIcons[mode]),
                title: Text(_themeModeLabel(l10n, mode)),
                trailing: mode == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () async {
                  await ref.read(themeModeProvider.notifier).set(mode);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccentColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).settingsAccentColor),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _accentPresets.map((color) {
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () async {
                await HapticFeedback.selectionClick();
                await ref.read(accentColorProvider.notifier).set(color);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: DesignTokens.animationNormal,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.onSurface
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
