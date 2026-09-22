import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/core/theme/theme_providers.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:honeyday/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Whether the user has completed onboarding (persisted).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(PreferencesKeys.onboardingComplete) ?? false;
});

/// Minimal router that only shows onboarding.
final _onboardingRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const _OnboardingWrapper(),
    ),
  ],
);

/// Root application widget for Honeyday.
class HoneydayApp extends ConsumerWidget {
  const HoneydayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    final themeModeValue = ref.watch(themeModeProvider);
    final themeMode = themeModeValue.hasValue ? themeModeValue.value! : ThemeMode.system;
    final accentColorValue = ref.watch(accentColorProvider);
    final accentColor = accentColorValue.hasValue ? accentColorValue.value! : AppColors.honeyAmber;

    final lightTheme = HoneydayTheme.lightTheme(seed: accentColor);
    final darkTheme = HoneydayTheme.darkTheme(seed: accentColor);

    final bool showOnboarding;
    if (onboardingAsync is AsyncData<bool>) {
      showOnboarding = !onboardingAsync.value;
    } else {
      showOnboarding = false;
    }

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
      routerConfig: showOnboarding ? _onboardingRouter : router,
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
  bool _persisted = false;

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.completed && !_persisted) {
      _persisted = true;
      unawaited(
        ref.read(sharedPreferencesProvider.future).then((prefs) {
          unawaited(prefs.setBool(PreferencesKeys.onboardingComplete, true));
        }),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(onboardingCompleteProvider);
      });
    }

    return const OnboardingPage();
  }
}
