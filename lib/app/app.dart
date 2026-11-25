import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/core/theme/theme_providers.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Whether the user has completed onboarding (persisted).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(PreferencesKeys.onboardingComplete) ?? false;
});

/// Root application widget for Honeyday.
class HoneydayApp extends ConsumerWidget {
  const HoneydayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    final themeModeValue = ref.watch(themeModeProvider);
    final themeMode = themeModeValue.hasValue
        ? themeModeValue.value!
        : ThemeMode.system;
    final accentColorValue = ref.watch(accentColorProvider);
    final accentColor = accentColorValue.hasValue
        ? accentColorValue.value!
        : AppColors.honeyAmber;

    final lightTheme = HoneydayTheme.lightTheme(seed: accentColor);
    final darkTheme = HoneydayTheme.darkTheme(seed: accentColor);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Gate the router's widget, not its location. Onboarding must not
      // consume or replace an incoming URL before the user can open it.
      builder: (context, child) {
        if (!onboardingAsync.hasValue) {
          if (onboardingAsync.hasError) {
            return _AppBootstrapError(
              onRetry: () => ref.invalidate(sharedPreferencesProvider),
            );
          }
          return const _AppBootstrapSplash();
        }
        if (onboardingAsync.value == false) return const _OnboardingWrapper();
        return child!;
      },
    );
  }
}

class _AppBootstrapError extends StatelessWidget {
  const _AppBootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.homeStorageUnavailable,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBootstrapSplash extends StatelessWidget {
  const _AppBootstrapSplash();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Wraps onboarding and handles navigation after completion.
class _OnboardingWrapper extends ConsumerStatefulWidget {
  const _OnboardingWrapper();

  @override
  ConsumerState<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<_OnboardingWrapper> {
  bool _persisting = false;

  Future<void> _persistAndComplete() async {
    if (_persisting) return;
    setState(() => _persisting = true);
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final saved = await prefs.setBool(
        PreferencesKeys.onboardingComplete,
        true,
      );
      if (!saved) throw StateError('Could not persist onboarding completion.');
      if (mounted) ref.invalidate(onboardingCompleteProvider);
    } on Object catch (error) {
      debugPrint('Honeyday: $error');
      if (!mounted) return;
      setState(() => _persisting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).agendaSaveError)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      completing: _persisting,
      onComplete: () => unawaited(_persistAndComplete()),
    );
  }
}
