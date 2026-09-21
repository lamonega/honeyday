import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeModeValue = ref.watch(themeModeProvider);
    final themeMode = themeModeValue.hasValue ? themeModeValue.value! : ThemeMode.system;
    final accentColorValue = ref.watch(accentColorProvider);
    final accentColor = accentColorValue.hasValue ? accentColorValue.value! : AppColors.honeyAmber;

    final accentName = _getAccentName(context, accentColor);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(label: AppLocalizations.of(context).settingsGeneral, colorScheme: colorScheme),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).settingsDarkMode),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? AppLocalizations.of(context).settingsThemeSystem
                  : themeMode == ThemeMode.dark
                      ? AppLocalizations.of(context).settingsThemeOn
                      : AppLocalizations.of(context).settingsThemeOff,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              final mode = value ? ThemeMode.dark : ThemeMode.light;
              unawaited(ref.read(themeModeProvider.notifier).set(mode));
            },
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
            onTap: () => unawaited(
              _showAccentColorPicker(context, ref, accentColor),
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(label: AppLocalizations.of(context).settingsAbout, colorScheme: colorScheme),
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
                duration: kAnimationDurationNormal,
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
