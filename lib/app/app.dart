import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared instance of [SharedPreferences] available app-wide.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Whether the user has completed onboarding (persisted).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('onboarding_complete') ?? false;
});

/// Persisted theme mode (light / dark / system).
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Persisted accent seed color as hex string.
final accentColorProvider =
    AsyncNotifierProvider<AccentColorNotifier, Color>(
  AccentColorNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final value = prefs.getString('theme_mode');
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('theme_mode', mode.name);
    ref.invalidateSelf();
  }
}

class AccentColorNotifier extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final hex = prefs.getString('accent_color');
    if (hex != null) {
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } on FormatException {
        return AppColors.honeyAmber;
      }
    }
    return AppColors.honeyAmber;
  }

  Future<void> set(Color color) async {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('accent_color', hex);
    ref.invalidateSelf();
  }
}

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
      title: 'Honeyday',
      debugShowCheckedModeBanner: false,
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
          unawaited(prefs.setBool('onboarding_complete', true));
        }),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(onboardingCompleteProvider);
      });
    }

    return const OnboardingPage();
  }
}
